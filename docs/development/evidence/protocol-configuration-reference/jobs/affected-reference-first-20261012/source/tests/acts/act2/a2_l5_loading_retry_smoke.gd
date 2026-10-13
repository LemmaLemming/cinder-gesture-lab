extends SceneTree
## TEST ONLY representative production entrance loading/transport/lifecycle.
## The preceding canonical completion prefix is fixture metadata, not gameplay.
## The protected checkpoint is an actual pristine native entrance capture, not
## an earned contact/B05 phase checkpoint. Fatal damage uses public take_damage;
## it is not attributed to any enemy, Ray/Foot proof or completed playthrough.
## Public menu request signals exercise Shell transactions, not mouse hit tests.
## Root owns promotion, imports and every dev.py native job. No native result yet.
const Shell: Script = preload("res://scripts/campaign/shell.gd")
const Registry: Script = preload("res://scripts/campaign/registry.gd")
const Attempts: Script = preload("res://scripts/campaign/attempts.gd")
const Store: Script = preload("res://scripts/campaign/save_store.gd")
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ProductionScene: PackedScene = preload("res://scenes/acts/act2/dead_london.tscn")
const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const Effects: Script = preload("res://scripts/effects.gd")
const Ray: Script = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const SCENE_PATH: String = "res://scenes/acts/act2/dead_london.tscn"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1", "A2-L2", "A2-L3", "A2-L4"]
const INPUTS: Array[String] = ["res://scenes/acts/act2/dead_london.tscn", "res://scripts/acts/act2/dead_london.gd", "res://scripts/acts/act2/dead_london_sentry_encounter.gd", "res://scripts/acts/act2/dead_london_sentry_presented_encounter.gd", "res://scripts/acts/act2/dead_london_sentry_presented_actor.gd", "res://scripts/acts/act2/dead_london_sentry_visual.gd", "res://scripts/acts/act2/dead_london_kit.gd", "res://scripts/campaign/shell.gd", "res://scripts/campaign/level.gd", "res://scripts/player.gd", "res://scripts/combat/threat_scheduler.gd", "res://scripts/combat/lane_mechanism.gd", "res://scripts/acts/act2/ray_scout_exchange.gd", "res://scripts/acts/act2/dead_london_bait.gd", "res://scripts/acts/act2/dead_london_sentry_actor.gd"]

class NativeTickProbe:
	extends Node
	signal tick_finished
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void:
		tick_finished.emit()

var _checks: int = 0
var _failures: int = 0
var _finished: bool = false
var _test_root: String
var _raw: Dictionary = {}
var _registry_bytes: String
var _source_bytes: Dictionary = {}
var _shell: CinderCampaignShell
var _preview: Node
var _candidate: Dictionary = {}
var _probe: NativeTickProbe
var _watch_restore: bool = false
var _restore_events: Array[String] = []
var _initial: Dictionary = {}
var _initial_payload: Dictionary = {}
var _old_audio: AudioBusLayout
var _old_fps: int

func _initialize() -> void:
	_test_root = "user://test-a2-l5-loading-%d/" % OS.get_process_id()
	_old_audio = AudioServer.generate_bus_layout()
	_old_fps = Engine.max_fps
	_run.call_deferred()

func _run() -> void:
	create_timer(80.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded representative loading fixture watchdog")
			_finish())
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_probe = NativeTickProbe.new()
	root.add_child(_probe)
	node_added.connect(_observe_added)
	_registry_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_raw = JSON.parse_string(_registry_bytes)
	for entry: Dictionary in _raw.levels:
		if entry.id == "A2-L5":
			entry.scene_path = SCENE_PATH
			entry.readiness = "accepted"
			entry.accepted_commit = "e".repeat(40)
			entry.api_revision = Registry.API_REVISION
	for path: String in INPUTS: _source_bytes[path] = FileAccess.get_file_as_string(path)
	_cleanup_paths()
	print("TEST ONLY L5 representative entrance: real production Main/Player/26-field local tuple, pristine protected checkpoint, public menu Continue/Resume/Retry and direct shared hurt fatal barrier; no earned contact/B05 phase/route/GUI pointer/art/balance claim")
	var registry: CinderCampaignRegistry = Registry.new(_raw)
	if not _expect(registry.last_error.is_empty(), "isolated registry preserves canonical 15/9 topology; only L5 readiness metadata injected"):
		_finish(); return
	if not await _capture_and_store_initial(registry): _finish(); return
	if not await _new_shell(): _finish(); return
	if not await _continue(_initial, "pristine production entrance"): _finish(); return
	_shell.menu.resume_requested.emit()
	for _index: int in range(8): await _probe.tick_finished
	if not _expect(not paused and not _shell.player.dead and _shell.campaign_error.is_empty(), "public Resume runs actual production simulation for eight native priority120 observations"):
		_finish(); return
	_shell.request_pause()
	await _settle()
	var current: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(paused and _shell.menu.page_name() == "pause" and _shell.campaign_error.is_empty() and not current.is_empty(), "public deferred Pause captures complete production state after real simulation"):
		_finish(); return
	_expect(current.level.local.scheduler.clock_s > _initial.level.local.scheduler.clock_s and current.player.world_actions.clock_s > _initial.player.world_actions.clock_s, "current native encounter/Player clocks advance without changing the protected entrance checkpoint")
	_expect(_same(_shell.attempts.state().story.checkpoint, _initial) and _same(_shell.attempts.story_snapshot(), current), "public Pause commits actual current snapshot and retains exact protected entrance tuple")
	if not _validate_current(current): _finish(); return
	var retired: Array[Dictionary] = _refs(_shell, true)
	_release_shell()
	_expect(_refs_freed(retired), "old whole actual production Shell/world/Player/actors/consumers/cues/scenery nodes are freed before disk Continue")
	if not await _new_shell() or not await _continue(current, "advanced representative entrance"): _finish(); return
	_shell.menu.resume_requested.emit()
	await _probe.tick_finished
	if not _expect(not paused and not _shell.player.dead, "public Resume allows native living simulation before genuine shared hurt"):
		_finish(); return
	var deaths: Array[bool] = []
	_shell.player.died.connect(func() -> void: deaths.append(true))
	# Actual damage transaction: no writes to HP, phase, clocks, motion or history.
	_shell.player.take_damage(_shell.player.max_hp * 4.0, Vector3.ZERO)
	await _settle()
	var dead: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(deaths.size() == 1 and paused and _shell.player.dead and _shell.player.hp == 0.0 and _shell.menu.page_name() == "pause" and _shell.campaign_error.is_empty() and not dead.is_empty(), "real public shared hurt emits one death and the production parent/Shell finish their deferred fatal barrier"):
		_finish(); return
	_expect(dead.level.local.scheduler.reservations.is_empty() and dead.level.local.sentry.parent.stage == "cancelled" and dead.level.local.sentry.foot.status != "running" and dead.level.local.rehearsal.status != "running", "fatal capture closes all real production leases/Foot consumers and retains finite parent history")
	_expect(_same(_shell.attempts.state().story.checkpoint, _initial) and _same(_shell.attempts.story_snapshot(), dead), "fatal durable snapshot never replaces the protected earlier living entrance")
	if not _validate_current(dead): _finish(); return
	retired = _refs(_shell, true)
	_release_shell()
	_expect(_refs_freed(retired), "fatal whole Shell and native subtree are released before independent dead Continue")
	if not await _new_shell() or not await _continue(dead, "actual fatal entrance"): _finish(); return
	var disk_before: String = FileAccess.get_file_as_string(_test_root + "campaign.json")
	_restore_events.clear(); _watch_restore = true
	_shell.menu.resume_requested.emit()
	await _settle()
	_watch_restore = false
	_expect(paused and _shell.player.dead and _shell.menu.page_name() == "pause" and _same(_shell.capture_campaign_snapshot(), dead) and FileAccess.get_file_as_string(_test_root + "campaign.json") == disk_before and _restore_events.is_empty(), "dead public Resume preserves all exact fatal clocks/resources/history/disk and executes no gameplay")
	retired = _refs(_shell, false)
	_restore_events.clear(); _watch_restore = true
	_shell.menu.retry_requested.emit()
	await _settle()
	_watch_restore = false
	var retried: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(paused and not _shell.player.dead and _shell.menu.page_name() == "resume" and _shell.campaign_error.is_empty() and _same(retried, _initial) and _restore_events.is_empty(), "public Retry quietly installs exact protected living entrance with no damage/action/defeat/progression events"):
		_finish(); return
	_expect(_refs_freed(retired), "Retry frees the old fatal native unit including all descendants before exposing its replacement")
	_expect(retried.player.resources == _initial.player.resources and _same(retried.equipment_ids, _initial.equipment_ids) and _same(retried.shell, _initial.shell) and retried.level.local.scheduler.clock_s < dead.level.local.scheduler.clock_s, "Retry genuinely rolls clocks back and preserves actual saved HP/ammo/gear/input/profile/camera")
	if not _validate_current(retried): _finish(); return
	_restore_events.clear(); _watch_restore = true
	await _settle()
	_watch_restore = false
	_expect(_same(_shell.capture_campaign_snapshot(), _initial) and _restore_events.is_empty() and _shell.attempts.state().completed_main == PREFIX and not _shell.active_level.is_completed(), "held paused recipient remains exact without duplicate callbacks/checkpoints/completion/refill")
	retired = _refs(_shell, true)
	_release_shell()
	_expect(_refs_freed(retired), "final whole Shell/production world and every captured descendant are released")
	_finish()

func _capture_and_store_initial(registry: CinderCampaignRegistry) -> bool:
	paused = true
	_preview = MainScene.instantiate()
	_preview.set("level_scene_path", SCENE_PATH)
	root.add_child(_preview)
	paused = true # Main.reset_lab resumes its constructor; close before any tick.
	await _settle() # Retire actual deferred cue publications; no unpaused physics.
	var hero: CinderPlayer = _preview.get("player") as CinderPlayer
	var level: CinderLevel = _preview.get("active_level") as CinderLevel
	if not _expect(is_instance_valid(hero) and is_instance_valid(level) and String(_preview.get("level_load_error")).is_empty() and level.level_id == "A2-L5", "standalone native Main constructs the genuine production L5 scene and shared Hero"):
		return false
	var player: Dictionary = hero.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	if not _expect(not player.is_empty() and not local.is_empty(), "paused standalone capture contains complete Player and strict full local packet: " + hero.last_snapshot_error + " / " + level.last_snapshot_error): return false
	_expect(player.world_actions.clock_s == 0.0 and local.local.scheduler.clock_s == 0.0 and local.local.stage == 0 and local.local.contacts.is_empty() and local.local.defeated_scouts.is_empty(), "initial representative tuple precedes simulation/contact/defeat; no fabricated earned progress")
	var observation: Dictionary = _preview.call("get_input_observation_state")
	var anchor: Vector2 = _preview.call("get_aim_anchor_normalized")
	var camera: Camera3D = _preview.get("camera") as Camera3D
	if not _expect(observation.sequence == 0 and observation.last_observation.is_empty(), "native preview has pristine public router state"): return false
	_initial = {"schema_version": 1, "level_id": "A2-L5", "scene_path": SCENE_PATH, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": player, "level": local, "shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": observation.sequence, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": _preview.get("_shake"), "difficulty_at_entry": local.local.profile_id}}
	var encoded: String = Exact.stringify(_initial)
	var transported: Dictionary = Exact.parse(encoded)
	if not _expect(not encoded.is_empty() and transported.get("accepted", false) and Exact.stringify(transported.value) == encoded, "actual whole production tuple exact typed transport preserves every scalar/resource/history field"): return false
	if not _same_call_fresh_candidate(hero, level, _initial): return false
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = PREFIX.duplicate()
	payload.story = {"kind": "story", "level_id": "A2-L5", "snapshot": _initial.duplicate(true), "checkpoint": _initial.duplicate(true)}
	if not _expect(model.state_error(payload).is_empty() and model.restore_session(payload), "public Attempts accepts TEST ONLY prior prefix with actual unmodified entrance snapshot/checkpoint"): return false
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	_initial_payload = model.state()
	if not _expect(store.write_payload(_initial_payload), "validated Store writes complete original Attempts payload to isolated path: " + store.last_error): return false
	var old: Array[Dictionary] = _refs(_preview, true)
	level.exit_level()
	_preview.free(); _preview = null
	return _expect(_refs_freed(old), "standalone native Main and production subtree are freed before actual Shell installation")

func _same_call_fresh_candidate(donor: CinderPlayer, level: CinderLevel, saved: Dictionary) -> bool:
	# Real production native recipients constructed and preflighted synchronously.
	# No yield, simulated tick or direct-space flush between construction/reader.
	var viewport := SubViewport.new()
	viewport.name = "TEST_OnlySynchronousProductionRecipient"
	viewport.size = Vector2i(270, 585)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var camera: Camera3D = (_preview.get("camera") as Camera3D).duplicate() as Camera3D
	world.add_child(camera)
	camera.current = true
	var fresh: CinderLevel = ProductionScene.instantiate() as CinderLevel
	world.add_child(fresh)
	var effects: PixelEffects = Effects.new()
	world.add_child(effects)
	var actor: CinderPlayer = PlayerScene.instantiate()
	actor.position = fresh.spawn_position() # Authored pre-entry placement only.
	var gear_ok: bool = actor.equipment.restore(saved.equipment_ids)
	var presentation_ok: bool = actor.set_presentation(LabSprite.presentation_for_act(2))
	actor.fx = effects
	world.add_child(actor)
	_candidate = {"viewport": viewport, "level": fresh, "effects": effects, "player": actor}
	var donor_before: String = Exact.stringify(donor.snapshot_state())
	var level_before: String = Exact.stringify(level.snapshot_state())
	var fresh_before: String = Exact.stringify(actor.snapshot_state())
	var prepared: bool = gear_ok and presentation_ok and fresh.enter_restore_candidate(actor, effects, _preview, saved.level, saved.player)
	var error: String = fresh.last_snapshot_error if not prepared else fresh.snapshot_error_with_player(saved.level, saved.player)
	var pure: bool = _expect(prepared and error.is_empty(), "same-call fresh paused production constructor/preflight before native physics: " + error)
	_expect(fresh.is_restore_candidate() and actor != donor and fresh != level and world != _preview.get("world"), "actual prospective recipient has independent native world/Player/actors before any quiet commit")
	_expect(Exact.stringify(actor.snapshot_state()) == fresh_before and Exact.stringify(donor.snapshot_state()) == donor_before and Exact.stringify(level.snapshot_state()) == level_before, "pure full saved-Player/production preflight changes neither fresh native Player nor donor components")
	_dispose_candidate()
	return pure and _failures == 0

func _new_shell() -> bool:
	_restore_events.clear(); _watch_restore = true
	_shell = Shell.new() as CinderCampaignShell
	if not _expect(_shell.configure_runtime(_raw, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"), "supported isolated public Shell.configure_runtime before native tree entry"): return false
	root.add_child(_shell)
	await _settle()
	_watch_restore = false
	return _expect(paused and _shell.player == null and _shell.menu.page_name() == "title" and _shell.campaign_error.is_empty() and _restore_events.is_empty(), "independent real disk Shell starts at Title and validates saves without gameplay events: " + _shell.campaign_error + str(_restore_events))

func _continue(expected: Dictionary, label: String) -> bool:
	_restore_events.clear(); _watch_restore = true
	_shell.menu.continue_story_requested.emit()
	await _settle()
	_watch_restore = false
	var actual: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(paused and _shell.menu.page_name() == "resume" and _shell.campaign_error.is_empty() and _same(actual, expected) and _restore_events.is_empty(), "public disk Continue quietly restores exact " + label + ": " + _shell.campaign_error + str(_restore_events)): return false
	var expected_payload: Dictionary = _initial_payload.duplicate(true)
	expected_payload.story.snapshot = expected.duplicate(true) # Comparison only.
	_expect(_same(_shell.attempts.state(), expected_payload), "Continue preserves exact complete original Attempts payload plus its actual current saved snapshot")
	_expect(_same(_shell.attempts.state().story.checkpoint, _initial), "Continue preserves protected actual entrance checkpoint")
	return _validate_current(actual)

func _validate_current(saved: Dictionary) -> bool:
	if not _expect(not saved.is_empty() and _shell.player.snapshot_error(saved.player).is_empty() and _shell.active_level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "public full staged Player/local preflight accepts the actual installed production tuple"): return false
	var local: Dictionary = saved.level.local
	var bindings: Dictionary = _shell.active_level.call("scheduler_bindings")
	_expect(bindings.owners.size() == 5 and bindings.floors.size() == 6 and bindings.world_root == _shell.world, "actual production binding scope retains all five unique owners and six authored floor IDs")
	_expect(local.size() == 26 and local.familiar.actors.size() == 2 and local.sentry.actor.actor.hp == 30.0 and local.sentry.foot.cycle == 0 and local.rehearsal.cycle == 0, "representative entrance retains two ordinary Scouts/finite30HP sentry/two unstarted Foot consumers")
	_expect(local.scheduler.reservations.is_empty() and local.contacts.is_empty() and local.defeated_scouts.is_empty() and not saved.level.progress.completed and not local.exit_requested, "focused loading/lifecycle introduces no enemy cycles/earned contacts/defeats/completion/exit")
	_expect(saved.player.presentation.id == "act2_survivor" and _same(_shell.player.equipment.snapshot(), saved.equipment_ids), "quiet production recipient retains actual Act2 shared presentation and original equipment")
	return _failures == 0

func _observe_added(node: Node) -> void:
	if not _watch_restore: return
	if node is CinderPlayer:
		var hero: CinderPlayer = node as CinderPlayer
		hero.fired.connect(func(_kind: String) -> void: _restore_events.append("player-fired"))
		hero.died.connect(func() -> void: _restore_events.append("player-death"))
		hero.equipment_changed.connect(func(_id: String) -> void: _restore_events.append("player-gear"))
		hero.world_action_executed.connect(func(_record: Dictionary) -> void: _restore_events.append("player-action"))
	elif node is CinderLevel:
		var level: CinderLevel = node as CinderLevel
		level.checkpoint_requested.connect(func(_level: String, _checkpoint: String, _kind: String) -> void: _restore_events.append("checkpoint"))
		level.completion_requested.connect(func(_level: String, _completion: String) -> void: _restore_events.append("completion"))
		level.contact_exit_requested.connect(func(_level: String, _exit: String) -> void: _restore_events.append("exit"))
	elif node is CinderLaneMechanism:
		var foot: CinderLaneMechanism = node as CinderLaneMechanism
		foot.hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _restore_events.append("foot-hit"))
	if node.has_signal("defeated"):
		node.connect("defeated", func(_id: String) -> void: _restore_events.append("actor-defeat"))
	if node.has_signal("phase_boundary_reached"):
		node.connect("phase_boundary_reached", func(_id: String) -> void: _restore_events.append("finite-phase-boundary"))
	if node.get_script() == Ray:
		node.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: _restore_events.append("ray-hit"))
		node.connect("scout_defeated", func(_id: String) -> void: _restore_events.append("ray-defeat"))
	for event: String in ["phase_checkpoint_eligible", "sentry_cleared", "runtime_failed"]:
		if node.has_signal(event): node.connect(event, func(_receipt: Variant) -> void: _restore_events.append(event))
	# Constructor/old-unit cleanup state_changed publications are not gameplay.
	# Exact installed native snapshots, zero live clocks, and retired weakrefs
	# validate quiet restoration independently; no no-phase-signal claim is made.

func _refs(unit: Node, include_root: bool) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	if include_root: refs.append({"path": String(unit.name), "ref": weakref(unit)})
	if unit is CinderCampaignShell and not include_root:
		var shell: CinderCampaignShell = unit as CinderCampaignShell
		if is_instance_valid(shell.world): _collect_refs(shell.world, refs)
	else:
		for child: Node in unit.get_children(): _collect_refs(child, refs)
	return refs

func _collect_refs(node: Node, refs: Array[Dictionary]) -> void:
	refs.append({"path": String(node.get_path()), "ref": weakref(node)})
	for child: Node in node.get_children(): _collect_refs(child, refs)

func _refs_freed(refs: Array[Dictionary]) -> bool:
	for row: Dictionary in refs:
		if (row.ref as WeakRef).get_ref() != null:
			print("L5 retained retired node: ", row.path)
			return false
	return not refs.is_empty()

func _release_shell() -> void:
	_watch_restore = false
	if is_instance_valid(_shell): _shell.free()
	_shell = null

func _dispose_candidate() -> void:
	if _candidate.is_empty(): return
	if is_instance_valid(_candidate.level): _candidate.level.exit_level()
	if is_instance_valid(_candidate.effects): _candidate.effects.clear_lab()
	if is_instance_valid(_candidate.viewport): _candidate.viewport.free()
	_candidate = {}

func _settle() -> void:
	for _index: int in range(8): await process_frame

func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)

func _expect(ok: bool, note: String) -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL L5 loading: " + note)
	return ok

func _cleanup_paths() -> void:
	for file: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = ProjectSettings.globalize_path(_test_root + file)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func _finish() -> void:
	if _finished: return
	_finished = true
	_watch_restore = false
	_dispose_candidate()
	if is_instance_valid(_preview):
		var level: CinderLevel = _preview.get("active_level") as CinderLevel
		if is_instance_valid(level): level.exit_level()
		_preview.free()
	_preview = null
	_release_shell()
	if is_instance_valid(_probe): _probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_bytes, "TEST ONLY injection preserves canonical registry bytes")
	for path: String in _source_bytes: _expect(FileAccess.get_file_as_string(path) == _source_bytes[path], "production/shared input remains unchanged during the focused fixture: " + path)
	_cleanup_paths()
	Engine.max_fps = _old_fps
	AudioServer.set_bus_layout(_old_audio)
	print("A2-L5 production loading retry smoke: %d checks, %d failures; real native entrance capture/prospective fresh construction/public disk Continue/fatal Resume/protected Retry/whole-unit cleanup only; representative unearned entrance checkpoint and prior-prefix metadata; no route/B05 phase/enemy fatal/GUI hit-testing/art/balance credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
