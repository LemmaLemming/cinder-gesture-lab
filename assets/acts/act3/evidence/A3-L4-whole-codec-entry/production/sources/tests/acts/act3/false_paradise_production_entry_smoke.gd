extends SceneTree
## TEST ONLY first-entry whole-codec production consumer; native qualification pending.
## Uses the published complete parent/core/codec; original source pins remain recorded.
## Only in-memory accepted scene metadata and predecessor prefix13 are seeded.
## Actual Main clock0 pair; no Hero HP/pose/clock/resources or source writes.
## One genuine entry, one routed pending dash, disk Continue and earlier Retry.
## No combat clear, Echo/core/helper/sun/full-route/canonical acceptance claim.

const MainScene = preload("res://scenes/main.tscn")
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const LEVEL: String = "res://scenes/acts/act3/a3_l4_false_paradise.tscn"
const RUNTIME: String = "res://scripts/acts/act3/false_paradise_level.gd"
const FIRST: String = "l4-rest-stalker"
const CHECKPOINT: String = "garden-rest-entry"

class PostActorBarrier extends Node:
	signal observed
	var waiting: bool = false
	var expired: bool = false
	var frames: int = 0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		if not get_tree().paused: _settled()
	func _process(_delta: float) -> void:
		if waiting:
			frames += 1
			if frames >= 120:
				expired = true
				_settled()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_settled.call_deferred()
	func _settled() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _checks: int = 0
var _failures: int = 0
var _host: Node
var _shell: CinderCampaignShell
var _hero: CinderPlayer
var _level: CinderLevel
var _scheduler: CinderThreatScheduler
var _barrier: PostActorBarrier
var _raw_registry: Dictionary = {}
var _registry_bytes: String = ""
var _test_root: String = ""
var _kit: Dictionary = {}
var _stats: Dictionary = {}
var _initial_resources: Dictionary = {}
var _story_core: Dictionary = {}
var _checkpoint: Dictionary = {}
var _entry_receipt: Dictionary = {}
var _saved_campaign: Dictionary = {}
var _saved_session: Dictionary = {}
var _events: Array[String] = []
var _quiet_events: Array[String] = []
var _watch_restore: bool = false
var _watched: Dictionary = {}
var _bound: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var entry_only: bool = args.size() == 1 and args[0] == "--first-entry-only"
	var error: String = "" if args.is_empty() or entry_only else "unsupported selector: " + str(args)
	if error.is_empty(): error = await _open()
	if _expect(error.is_empty(), "TEST prefix13/accepted row installs the actual clock0 whole production pair", error):
		error = await _first_entry()
		if _expect(error.is_empty(), "real first entry earns and persists its actual protected checkpoint", error) and not entry_only:
			error = await _save_pending_dash()
			if _expect(error.is_empty(), "real swipe supplies a changed pending-dash whole SaveStore format2 unit", error):
				error = _malformed_controls()
				if _expect(error.is_empty(), "copy-only malformed route/clock/death/source/context reject atomically", error):
					error = await _fresh_continue()
					if _expect(error.is_empty(), "fresh disk Continue quietly restores the exact live Player/local/Shell unit", error):
						error = await _retry()
						_expect(error.is_empty(), "public Retry restores the earlier earned checkpoint and GUI Resume is consumed", error)
	if not error.is_empty(): print("FIRST MEANINGFUL L4 ENTRY PRODUCTION FAILURE; later actions unattempted: ", error, "; ", _diagnostic())
	await _dispose_host(true)
	if node_added.is_connected(_watch_new_node): node_added.disconnect(_watch_new_node)
	_expect(_registry_bytes.is_empty() or FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_bytes, "canonical registry bytes remain unchanged")
	_cleanup_path(_test_root)
	print("TEST ONLY False Paradise first-entry production: %d checks; failures: %d. Actual first-entry Scheduler1/whole local1 Save, disk Continue, protected Retry/consumed GUI Resume only; seeded accepted metadata/prefix13 are not earned campaign clears. No combat/full-route/core/Echo/sun/transition/art/native-OS claim." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _open() -> String:
	# Actual public Main fresh scene replacement while paused, before physics.
	_host = MainScene.instantiate()
	root.add_child(_host)
	_host.call("open_bench")
	if not paused or not _host.call("load_level_scene", LEVEL): return "public Main scene load refused: " + String(_host.get("level_load_error"))
	_host.call("open_bench")
	_hero = _host.get("player") as CinderPlayer
	_level = _host.get("active_level") as CinderLevel
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if is_instance_valid(_level) else null
	if not is_instance_valid(_hero) or not is_instance_valid(_level) or not is_instance_valid(_scheduler): return "actual Main seed bindings unavailable"
	var error: String = _live_error()
	if not error.is_empty(): return error
	if _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0 or not _hero.get_world_action_records().is_empty() or not (_level.get("sources") as Dictionary).is_empty(): return "fresh real pair advanced or manufactured source/history"
	var camera: Camera3D = _host.get("camera") as Camera3D
	var hud: GameHUD = _host.get("hud") as GameHUD
	# Public status refresh uses the actual fresh actor/objective and changes no
	# mechanics. The owner writer checks this real native Camera/HUD context.
	hud.update_status(_hero.hp, _hero.max_hp, _hero.shells, _hero.max_shells, 0, _level.objective_text)
	var player: Dictionary = _hero.snapshot_state()
	var local: Dictionary = _level.snapshot_state_for_presentation(camera, hud)
	if player.is_empty() or local.is_empty(): return "actual zero-tick full writer refused: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	error = _level.snapshot_error_with_player(local, player)
	if not error.is_empty(): return "actual zero-tick pair: " + error
	_kit = _hero.equipment.snapshot()
	_stats = _hero.equipment.resolved_stats()
	_initial_resources = player.resources.duplicate(true)
	var seed: Dictionary = {"schema_version": 1, "level_id": "A3-L4", "scene_path": LEVEL, "paused": true, "equipment_ids": _kit.duplicate(true), "player": player, "level": local, "shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [0.5,0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Value.vector3(camera.global_position - Vector3(0,18,13)), "shake_left_s": 0.0, "difficulty_at_entry": local.local.world.profile_id}}
	_registry_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var raw: Variant = JSON.parse_string(_registry_bytes)
	if not raw is Dictionary: return "canonical registry cannot be read"
	_raw_registry = raw.duplicate(true)
	var replaced: bool = false
	for row: Dictionary in _raw_registry.levels:
		if row.id == "A3-L4":
			row.scene_path = LEVEL
			row.readiness = "accepted" # TEST ONLY in memory, never written.
			row.accepted_commit = "a".repeat(40)
			row.api_revision = Registry.API_REVISION
			replaced = true
	if not replaced: return "canonical A3-L4 metadata row missing"
	_test_root = "user://test-act3-garden-entry-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	await _dispose_host(false)
	if not node_added.is_connected(_watch_new_node): node_added.connect(_watch_new_node)
	error = await _new_shell()
	if not error.is_empty(): return error
	var prefix: Array[String] = []
	prefix.assign(_shell.registry.main_route().slice(0,13))
	if prefix.size() != 13 or prefix[12] != "A3-L3" or not _shell.registry.scene_error("A3-L4").is_empty(): return "TEST prefix13/scene identity refused"
	var session: Dictionary = _shell.attempts.state()
	session.completed_main = prefix.duplicate() # TEST ONLY predecessor metadata.
	session.story = {"kind": "story", "level_id": "A3-L4", "snapshot": seed.duplicate(true), "checkpoint": seed.duplicate(true)}
	error = _shell.attempts.state_error(session)
	if not error.is_empty() or not _shell.attempts.restore_session(session): return "public complete seed rejected: " + error + "; " + _shell.attempts.last_error
	_story_core = _campaign_core(session)
	_shell.menu.continue_story_requested.emit()
	error = await _settle_shell("resume")
	if error.is_empty(): error = _bind_runtime()
	if not error.is_empty(): return error
	if not _same(_shell.capture_campaign_snapshot(), seed): return "initial public Continue changed the genuine clock0 seed"
	_shell.request_pause()
	error = await _settle_shell("pause")
	if not error.is_empty(): return error
	if not _same(_shell.capture_campaign_snapshot(), seed): return "initial public pause changed clock0 whole seed"
	return _disk_error(_shell.attempts.state())


func _new_shell() -> String:
	_shell = Shell.new()
	_host = _shell
	if not _shell.configure_runtime(_raw_registry, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"): return "public Shell.configure_runtime refused: " + _shell.campaign_error
	root.add_child(_shell)
	for _i: int in range(4): await process_frame
	return "" if paused and _shell.campaign_error.is_empty() and _shell.menu != null and _shell.menu.page_name() == "title" else "fresh production title/load refused: " + _shell.campaign_error


func _settle_shell(page: String) -> String:
	for _i: int in range(40):
		await process_frame
		if not _shell.campaign_error.is_empty(): return _shell.campaign_error
		if paused and not _shell.is_pause_requested() and _shell.menu.page_name() == page and is_instance_valid(_shell.active_level): return ""
	return "public Shell did not settle to paused " + page


func _bind_runtime() -> String:
	_hero = _shell.player
	_level = _shell.active_level
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if is_instance_valid(_level) else null
	var error: String = _live_error()
	if not error.is_empty(): return error
	if _level.is_restore_candidate() or not _same(_hero.equipment.snapshot(), _kit) or not _same(_hero.equipment.resolved_stats(), _stats) or not _same(_hero.snapshot_state().resources, _initial_resources): return "quiet recipient changed actual gear/resources or remains a candidate"
	_barrier = PostActorBarrier.new()
	_barrier.name = "TestOnlyFalseParadiseEntryPostConsumerBarrier"
	_shell.add_child(_barrier)
	if not _bound.has(_hero.get_instance_id()):
		_bound[_hero.get_instance_id()] = true
		_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
		_hero.died.connect(func() -> void: _events.append("hero_death"))
		_hero.equipment_changed.connect(func(_id: String) -> void: _events.append("equipment"))
	if not _bound.has(_level.get_instance_id()):
		_bound[_level.get_instance_id()] = true
		_level.checkpoint_requested.connect(func(_id: String, _checkpoint_id: String, _kind: String) -> void: _events.append("checkpoint"))
		_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
		_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _events.append("exit"))
	return ""


func _live_error() -> String:
	if not is_instance_valid(_host) or not is_instance_valid(_hero) or not is_instance_valid(_level) or not is_instance_valid(_scheduler): return "actual host/Player/parent/Scheduler unavailable"
	if _level.scene_file_path != LEVEL or _level.get_script().resource_path != RUNTIME or _level.level_id != "A3-L4" or _level.local_snapshot_version != 1 or _hero.presentation_id != "act3_traveller": return "actual A3-L4/shared presentation identity differs"
	var error: String = String(_level.call("runtime_error"))
	if not error.is_empty(): return error
	var world: Node3D = _host.get("world") as Node3D
	var camera: Camera3D = _host.get("camera") as Camera3D
	if _level.hero != _hero or _level.shared_shell != _host or _level.effects != _host.get("fx") or _level.get_parent() != world or _hero.get_parent() != world or camera == null or camera.get_parent() != world or camera.get_viewport().get_camera_3d() != camera or camera.get_world_3d() != _level.get_world_3d(): return "actual live World/Hero/effects/current Camera bindings differ"
	return ""


func _first_entry() -> String:
	var error: String = _resume_consumed()
	if not error.is_empty(): return error
	for _i: int in range(120):
		error = await _tick()
		if not error.is_empty(): return error
		var state: Dictionary = _level.call("state")
		if not state.route.entries.is_empty() and _entry_receipt.is_empty():
			_entry_receipt = state.route.entries[0].duplicate(true)
			var body: CollisionShape3D = _hero.get_node_or_null("BodyCollision") as CollisionShape3D
			if body == null or not body.shape is CapsuleShape3D or _entry_receipt.id != "offered-rest" or _entry_receipt.beat != 1 or _entry_receipt.clock_s != _scheduler.get_clock() or not _same(_entry_receipt.hero_position, Value.vector3(_hero.global_position)) or _entry_receipt.capsule_radius != (body.shape as CapsuleShape3D).radius or body.global_position.z + (body.shape as CapsuleShape3D).radius > 60.0: return "first entry lacks independently observed real clock/capsule crossing"
		var session: Dictionary = _shell.attempts.state()
		if session.story.checkpoint.level.progress.checkpoint_id == CHECKPOINT:
			_checkpoint = session.story.checkpoint.duplicate(true)
			break
	if _checkpoint.is_empty(): return "first native checkpoint was not dispatched/persisted within2s"
	if not _same(_campaign_core(_shell.attempts.state()), _story_core) or _events.count("checkpoint") != 1 or _events.has("completion") or _events.has("exit"): return "first checkpoint changed story metadata or delivered extra progress"
	var progress: Dictionary = _checkpoint.level.progress
	var local: Dictionary = _checkpoint.level.local
	if not _same(progress.checkpoint_ids, {CHECKPOINT: "encounter"}) or progress.checkpoint_kind != "encounter" or progress.completed or local.scheduler.schema_version != 1 or local.route.entries.size() != 1 or not _same(local.route.entries[0], _entry_receipt) or not local.route.pending_checkpoint_boundaries.is_empty() or not local.route.deaths.is_empty() or not _same(local.sources.keys(), [FIRST]) or local.sources[FIRST].actor.hp != 36.0 or not local.core.is_empty() or local.sun.started: return "protected first-entry whole unit contains extra topology/earned state"
	return _disk_error(_shell.attempts.state())


func _tick() -> String:
	# Every wait is bounded. A checkpoint's legitimate deferred pause may
	# settle and auto-resume before the next post-actor observation.
	for _i: int in range(40):
		if not paused: break
		await process_frame
		if not _shell.campaign_error.is_empty(): return _shell.campaign_error
	if paused: return "native checkpoint operation failed to auto-resume"
	_barrier.frames = 0
	_barrier.expired = false
	_barrier.waiting = true
	await _barrier.observed
	if _barrier.expired: return "native post-actor barrier did not run within120 process frames"
	var error: String = _live_error()
	if not error.is_empty(): return error
	if _hero.dead or _hero.hp != float(_initial_resources.hp) or not _same(_kit, _hero.equipment.snapshot()) or not _same(_stats, _hero.equipment.resolved_stats()) or _events.has("fired_blast") or _events.has("hero_death") or _events.has("completion") or _events.has("exit"): return "first-entry observation changed resources/kit or earned forbidden contact/completion"
	if _scheduler.get_clock() > 3.0: return "bounded first-entry3s budget exceeded"
	return ""


func _save_pending_dash() -> String:
	var error: String = ""
	for _i: int in range(60):
		var response: Dictionary = _hero.get_threat_response_state()
		if response.stable and float(response.motion.dash_left_s) == 0.0 and float(response.dash_cooldown_left_s) == 0.0: break
		error = await _tick()
		if not error.is_empty(): return error
	var before: Dictionary = _hero.get_threat_response_state()
	if not before.stable or float(before.motion.dash_left_s) != 0.0 or float(before.dash_cooldown_left_s) != 0.0: return "actual grounded dash readiness did not settle within1s"
	error = _swipe_left()
	if not error.is_empty(): return error
	if not _shell.request_pause_deferred(): return "public complete-tick pending-dash pause refused"
	error = await _settle_shell("pause")
	if not error.is_empty(): return error
	_saved_campaign = _shell.capture_campaign_snapshot()
	_saved_session = _shell.attempts.state()
	if _saved_campaign.is_empty(): return "actual changed whole writer refused: " + _shell.campaign_error
	if _same(_saved_campaign, _checkpoint) or not _same(_saved_session.story.snapshot, _saved_campaign) or not _same(_saved_session.story.checkpoint, _checkpoint) or not _same(_campaign_core(_saved_session), _story_core): return "changed save lost protected checkpoint/story or is not a representative later unit"
	if float(_hero.get_threat_response_state().motion.dash_left_s) <= 0.0 or _saved_campaign.player.world_actions.pending_dash.is_empty() or _saved_campaign.shell.input_sequence != 1 or _saved_campaign.shell.last_input_observation.kind != "swipe_release" or _saved_campaign.shell.last_input_observation.accepted or _events.count("fired_dash") != 1: return "saved changed state lacks the actual routed unfinished dash/input"
	return _disk_error(_saved_session)


func _swipe_left() -> String:
	var camera: Camera3D = _shell.camera
	var right: Vector3 = camera.global_basis.x
	var down: Vector3 = camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	var world_direction := Vector3.LEFT
	var screen_direction: Vector2 = Vector2(world_direction.dot(right.normalized()), world_direction.dot(down.normalized())).normalized()
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5,0.60)
	var finish: Vector2 = start + screen_direction * size.x * 0.22
	if not root.get_visible_rect().has_point(finish) or finish.y < 100.0: return "routed ordinary LEFT release lies outside the native input area"
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = finish
	root.push_input(release, true)
	return "" if float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0 and _shell.get_aim_anchor_normalized().distance_to(finish / size) < 0.000001 else "real final release did not begin/retain the shared dash anchor"


func _malformed_controls() -> String:
	var original: Dictionary = _saved_campaign.duplicate(true)
	for label: String in ["route_clock", "scheduler_clock", "unearned_death", "omitted_first_source", "foreign_context"]:
		var bad: Dictionary = original.duplicate(true)
		match label:
			"route_clock": bad.level.local.route.entries[0].clock_s = bad.level.local.scheduler.clock_s + 0.125
			"scheduler_clock": bad.level.local.scheduler.clock_s += 0.00000001
			"unearned_death": bad.level.local.route.deaths[FIRST] = {"clock_s": bad.level.local.scheduler.clock_s, "source_position": bad.level.local.sources[FIRST].actor.position.duplicate()}
			"omitted_first_source": bad.level.local.sources.erase(FIRST)
			"foreign_context": bad.level.local.world.encounter_id += "/foreign"
		var supplied: Dictionary = bad.duplicate(true)
		var before: Dictionary = _observation()
		var error: String = _level.snapshot_error_with_player(bad.level, bad.player)
		if error.is_empty() or _level.restore_state(bad.level): return "malformed " + label + " accepted by live public whole guard"
		var bad_session: Dictionary = _saved_session.duplicate(true)
		bad_session.story.snapshot = bad
		var session_copy: Dictionary = bad_session.duplicate(true)
		var attempts_error: String = _shell.attempts.state_error(bad_session)
		if attempts_error.is_empty() or _shell.attempts.restore_session(bad_session): return "malformed " + label + " accepted by public Attempts fresh preflight"
		# Positive public revalidation constructs/disposes only its owned inert
		# validation candidate and clears diagnostic failure; it does not commit.
		var positive: String = _shell.attempts.state_error(_saved_session)
		if not positive.is_empty() or not _same(before, _observation()) or not _same(bad, supplied) or not _same(bad_session, session_copy) or not _same(original, _shell.capture_campaign_snapshot()): return "malformed " + label + " or positive pure validation mutated live state/input/disk/supplied data: " + positive
		_expect(true, "atomic copied " + label + " rejected by paired level and public Attempts", error + "; " + attempts_error)
	return ""


func _fresh_continue() -> String:
	var refs: Array[WeakRef] = []
	_collect_refs(_shell, refs)
	var ids: Dictionary = _native_ids()
	var events: Array[String] = _events.duplicate()
	var camera: Dictionary = _camera_packet()
	await _dispose_host(false)
	_quiet_events.clear()
	_watch_restore = true
	var error: String = await _new_shell()
	if error.is_empty():
		_shell.menu.continue_story_requested.emit()
		error = await _settle_shell("resume")
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _same(events, _events): return "fresh disk Continue emitted gameplay/progression: " + str(_quiet_events)
	error = _bind_runtime()
	if not error.is_empty(): return error
	if not _fresh_ids(ids) or not _same(_saved_campaign, _shell.capture_campaign_snapshot()) or not _same(_saved_session, _shell.attempts.state()) or not _same(camera, _camera_packet()): return "fresh Continue reused donor or changed full native unit/story/resources/history/input/Camera"
	error = await _released_error(refs, _saved_campaign)
	return error if not error.is_empty() else _disk_error(_saved_session)


func _retry() -> String:
	var refs: Array[WeakRef] = []
	_collect_refs(_shell.world, refs)
	if is_instance_valid(_barrier): refs.append(weakref(_barrier))
	var ids: Dictionary = _native_ids()
	var events: Array[String] = _events.duplicate()
	if is_instance_valid(_barrier): _barrier.queue_free()
	_quiet_events.clear()
	_watch_restore = true
	_shell.request_retry()
	var error: String = await _settle_shell("resume")
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _same(events, _events): return "protected earlier Retry emitted gameplay/progression: " + str(_quiet_events)
	error = _bind_runtime()
	if not error.is_empty(): return error
	var actual: Dictionary = _shell.capture_campaign_snapshot()
	var session: Dictionary = _shell.attempts.state()
	if not _fresh_ids(ids) or not _same(actual, _checkpoint) or not _same(session.story.checkpoint, _checkpoint) or not _same(session.story.snapshot, _checkpoint) or not _same(_campaign_core(session), _story_core): return "Retry did not install exact earlier protected unit/story in fresh recipients"
	error = await _released_error(refs, _checkpoint)
	if error.is_empty(): error = _disk_error(session)
	if error.is_empty(): error = _resume_consumed()
	if not error.is_empty(): return error
	# Pause immediately through the public operation; no fixture clock/resource
	# rewrite and no resumed tick is needed to prove consumed GUI input.
	_shell.request_pause()
	error = await _settle_shell("pause")
	if not error.is_empty(): return error
	return _disk_error(_shell.attempts.state())


func _resume_consumed() -> String:
	var button: Control = _shell.menu.find_child("ResumeButton", true, false) as Control
	if not paused or not _shell.menu.is_open() or button == null or not button.is_visible_in_tree(): return "actual visible GUI Resume button unavailable"
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
	if not handled or not root.is_input_handled() or paused or _shell.menu.is_open() or _hero.get_world_action_clock() != before.clock or _hero.hp != before.hp or _hero.shells != before.shells or not _same(_shell.get_input_observation_state(), before.input) or not _same(_hero.get_world_action_records(), before.history): return "GUI Resume was not consumed or changed actual actions/input/resources"
	return ""


func _disk_error(expected: Dictionary) -> String:
	var reader: CinderSaveStore = Store.new(_test_root + "campaign.json")
	var payload: Dictionary = reader.read_payload()
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(_test_root + "campaign.json"))
	if not reader.last_error.is_empty() or reader.loaded_backup or reader.generation < 1 or not envelope is Dictionary or envelope.get("format_version") != 2 or not envelope.get("payload_json") is String or envelope.payload_json.sha256_text() != envelope.get("sha256") or not _same(payload, expected): return "independent production SaveStore format2 differs: " + reader.last_error
	var wire: String = ExactJson.stringify(payload)
	var decoded: Dictionary = ExactJson.parse(wire)
	return "" if not wire.is_empty() and decoded.get("accepted", false) and String(decoded.get("error", "")).is_empty() and _same(decoded.get("value"), expected) else "complete actual native durable payload changed in exact transport"


func _observation() -> Dictionary:
	return {"player": _hero.snapshot_state(), "level": _level.call("state"), "scheduler": _scheduler.snapshot_state(_level.call("scheduler_bindings")), "events": _events.duplicate(), "quiet": _quiet_events.duplicate(), "attempts": _shell.attempts.state(), "disk": FileAccess.get_file_as_string(_test_root + "campaign.json"), "camera": _camera_packet(), "input": _shell.get_input_observation_state(), "ids": _native_ids()}


func _camera_packet() -> Dictionary:
	var camera: Camera3D = _host.get("camera") as Camera3D
	return {"transform": camera.global_transform, "projection": camera.projection, "keep_aspect": camera.keep_aspect, "size": camera.size, "near": camera.near, "far": camera.far, "h_offset": camera.h_offset, "v_offset": camera.v_offset}


func _native_ids() -> Dictionary:
	var source: Node = (_level.get("sources") as Dictionary).get(FIRST) as Node
	return {"hero": _hero.get_instance_id(), "level": _level.get_instance_id(), "scheduler": _scheduler.get_instance_id(), "source": source.get_instance_id() if is_instance_valid(source) else 0, "camera": (_host.get("camera") as Camera3D).get_instance_id()}


func _fresh_ids(previous: Dictionary) -> bool:
	var current: Dictionary = _native_ids()
	for key: String in previous:
		if int(previous[key]) <= 0 or int(current[key]) <= 0 or current[key] == previous[key]: return false
	return true


func _campaign_core(session: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in ["completed_main", "completed_optional", "reward_ids", "unlocked_equipment", "last_replay_equipment"]: result[key] = session[key].duplicate(true)
	result["side_attempt"] = session.side_attempt
	result["story_identity"] = {"kind": session.story.kind, "level_id": session.story.level_id}
	return result


func _watch_new_node(node: Node) -> void:
	if not _watch_restore or not is_instance_valid(_shell) or not _shell.is_ancestor_of(node) or _watched.has(node.get_instance_id()): return
	_watched[node.get_instance_id()] = true
	if node is CinderPlayer:
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _quiet_events.append("restore_action"))
		node.fired.connect(func(_kind: String) -> void: _quiet_events.append("restore_fire"))
		node.died.connect(func() -> void: _quiet_events.append("restore_hero_death"))
		node.equipment_changed.connect(func(_id: String) -> void: _quiet_events.append("restore_equipment"))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _checkpoint_id: String, _kind: String) -> void: _quiet_events.append("restore_checkpoint"))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void: _quiet_events.append("restore_completion"))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _quiet_events.append("restore_exit"))
	if node is CinderThreatCue:
		node.state_changed.connect(func(_state: Dictionary) -> void: _quiet_events.append("restore_threat_cue"))
	if node is CinderAct3SunboundStalker:
		node.state_changed.connect(func(_state: Dictionary) -> void: _quiet_events.append("restore_source_state"))
	if node.has_signal("hit_resolved"): node.connect("hit_resolved", func(_result: Dictionary) -> void: _quiet_events.append("restore_source_hit"))
	if node.has_signal("died") and not node is CinderPlayer: node.connect("died", func(_where: Vector3) -> void: _quiet_events.append("restore_source_death"))


func _collect_refs(node: Node, refs: Array[WeakRef]) -> void:
	if not is_instance_valid(node): return
	refs.append(weakref(node))
	for child: Node in node.get_children(): _collect_refs(child, refs)


func _released_error(refs: Array[WeakRef], expected: Dictionary) -> String:
	for _i: int in range(8):
		var freed: bool = true
		for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
		if freed: return "" if paused and _same(expected, _shell.capture_campaign_snapshot()) else "receiver changed during donor retirement"
		await process_frame
	return "actual donor native World/Player/source/camera/FX/fixture nodes remained alive"


func _dispose_host(check_cleanup: bool) -> void:
	_watch_restore = false
	if is_instance_valid(_shell) and is_instance_valid(_level) and not paused:
		if _shell.request_pause_deferred():
			var settlement: String = await _settle_shell("pause")
			if check_cleanup: _expect(settlement.is_empty(), "supported completed-tick pause precedes owner retirement", settlement)
	var refs: Array[WeakRef] = []
	_collect_refs(_host, refs)
	if is_instance_valid(_level): _level.exit_level()
	if is_instance_valid(_host):
		if _host.get_parent() == root: root.remove_child(_host)
		_host.queue_free()
	paused = false
	for _i: int in range(5): await process_frame
	await create_timer(0.15,true,false,true).timeout
	var freed: bool = true
	for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
	if check_cleanup: _expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("practice_targets").is_empty() and get_nodes_in_group("lab_weapons").is_empty(), "actual host/Player/source/FX retire without native/group residue")
	_host = null
	_shell = null
	_hero = null
	_level = null
	_scheduler = null
	_barrier = null


func _cleanup_path(path: String) -> void:
	if _test_root.is_empty() or not path.begins_with(_test_root) or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)): return
	for directory: String in DirAccess.get_directories_at(path): _cleanup_path(path.path_join(directory))
	for filename: String in DirAccess.get_files_at(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _same(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right): return false
	if left is float:
		var a := PackedByteArray()
		var b := PackedByteArray()
		a.resize(8)
		b.resize(8)
		a.encode_double(0, left)
		b.encode_double(0, right)
		return a == b
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _same(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _same(left[index], right[index]): return false
		return true
	if typeof(left) in [TYPE_VECTOR2, TYPE_VECTOR3, TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_COLOR, TYPE_AABB]: return var_to_bytes(left) == var_to_bytes(right)
	return left == right

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(label + (": " + detail if not detail.is_empty() else ""))
	return ok


func _diagnostic() -> String:
	return str({"paused": paused, "clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0, "hero": _hero.global_position if is_instance_valid(_hero) else null, "parent": _level.call("state") if is_instance_valid(_level) else {}, "campaign_error": _shell.campaign_error if is_instance_valid(_shell) else "no Shell", "events": _events, "quiet_events": _quiet_events})
