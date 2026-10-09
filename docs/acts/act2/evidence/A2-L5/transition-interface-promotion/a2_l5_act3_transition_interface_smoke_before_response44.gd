extends "res://tests/acts/act2/a2_l5_loading_retry_smoke.gd"
## TEST ONLY completion/contact transport through the real campaign Shell.
## First capture/validate an actual strict pristine production L5 entrance.
## Then use the existing plain TEST CinderLevel coda component, with actual
## unentered production geometry, for public completion/contact interface flow.
## The prior completed prefix is representative metadata, explicitly unearned.
## This never constructs a strict production terminal tuple or seeds live
## HP/phase/clock/pose, boss admission, scheduler proof, receipts or host stage.
## Actual A3-L1 registry entry, constructor, Player, Attempts and disk are used.
## Root owns promotion/import/dev.py; static draft only, no native result.
const FLOW_SCENE: String = "res://tests/acts/act2/fixtures/a2_l5_production_coda_component.tscn"
const FLOW_EXIT: Rect2 = Rect2(-1.0, -42.0, 2.0, 7.0)
const FLOW_DESTINATION: String = "res://scenes/acts/act3/a3_l1.tscn"
const FLOW_COMPLETION_ID: String = "test-interface-completion"
const FLOW_EXIT_ID: String = "test-interface-act3-contact"
const FLOW_MAX_TICKS: int = 180
const FLOW_INPUTS: Array[String] = ["res://tests/acts/act2/a2_l5_loading_retry_smoke.gd", FLOW_SCENE, "res://scripts/campaign/attempts.gd", "res://scripts/campaign/save_store.gd", "res://scripts/campaign/registry.gd", "res://scripts/campaign/exact_json.gd", FLOW_DESTINATION, "res://scripts/acts/act3/twin_suns_level.gd", "res://scripts/acts/act3/twin_suns.gd", "res://scripts/acts/act3/sunbound_stalker.gd", "res://data/campaign/act3/a3_l1_encounters.json"]
var _flow_production: Dictionary = {}
var _flow_completed: Array[String] = []
var _flow_exits: Array[String] = []

func _run() -> void:
	_test_root = "user://test-a2-l5-act3-interface-%d/" % OS.get_process_id()
	create_timer(80.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded focused completion/contact interface watchdog")
			_finish())
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_probe = NativeTickProbe.new()
	root.add_child(_probe)
	node_added.connect(_observe_added)
	_registry_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_raw = JSON.parse_string(_registry_bytes)
	for path: String in INPUTS + FLOW_INPUTS: _source_bytes[path] = FileAccess.get_file_as_string(path)
	_source_bytes[get_script().resource_path] = FileAccess.get_file_as_string(get_script().resource_path)
	_cleanup_paths()
	print("TEST ONLY L5 -> actual A3-L1 interface: genuine pristine production entrance codec separately; completion/contact source is plain TEST CinderLevel with unentered production coda geometry. No strict production terminal, earned coda, boss defeat or full-route claim.")
	if not await _flow_strict_entrance(): _finish(); return
	if not await _flow_seed_interface(): _finish(); return
	if not await _new_shell() or not await _flow_continue(_initial, "pristine TEST interface coda"): _finish(); return
	if not await _flow_transition(): _finish(); return
	_finish()

func _flow_registry(path: String) -> CinderCampaignRegistry:
	_raw = JSON.parse_string(_registry_bytes)
	for entry: Dictionary in _raw.levels:
		if entry.id == "A2-L5":
			entry.scene_path = path
			entry.readiness = "accepted"
			entry.accepted_commit = "e".repeat(40)
			entry.api_revision = Registry.API_REVISION
	return Registry.new(_raw) as CinderCampaignRegistry

func _flow_strict_entrance() -> bool:
	var registry: CinderCampaignRegistry = _flow_registry(SCENE_PATH)
	if not _expect(registry.last_error.is_empty() and registry.next_main("A2-L5") == "A3-L1" and registry.is_playable("A3-L1") and registry.entry("A3-L1").scene_path == FLOW_DESTINATION, "isolated L5 readiness injection retains the actual accepted canonical A3-L1 destination"): return false
	# Reuse the already reviewed native capture/public fresh preflight helper.
	# No inherited long loading/fatal/Retry route is executed by this fixture.
	if not await _capture_and_store_initial(registry): return false
	_flow_production = _initial.duplicate(true)
	return _expect(_flow_production.scene_path == SCENE_PATH and _flow_production.level.local.size() == 26 and _flow_production.level.local.stage == 0 and _flow_production.level.local.sentry.parent.stage == "dormant" and not _flow_production.level.progress.completed and _flow_production.level.progress.contact_exit_id == "", "actual strict production entrance stays separate and cannot stand in for a terminal donor")

func _flow_seed_interface() -> bool:
	var registry: CinderCampaignRegistry = _flow_registry(FLOW_SCENE)
	var canonical: CinderCampaignRegistry = Registry.new() as CinderCampaignRegistry
	if not _expect(registry.last_error.is_empty() and registry.main_route() == canonical.main_route() and registry.entry("A3-L1") == canonical.entry("A3-L1"), "only TEST L5 source scene/readiness differs; all canonical route and A3-L1 metadata remain exact"): return false
	_cleanup_paths()
	paused = true
	_preview = MainScene.instantiate()
	_preview.set("level_scene_path", FLOW_SCENE)
	root.add_child(_preview)
	paused = true # Actual Main.reset_lab resumes; close before any native tick.
	await _settle()
	var hero: CinderPlayer = _preview.get("player") as CinderPlayer
	var level: CinderLevel = _preview.get("active_level") as CinderLevel
	if not _expect(is_instance_valid(hero) and is_instance_valid(level) and String(_preview.get("level_load_error")).is_empty() and level.scene_file_path == FLOW_SCENE, "actual Main constructs the existing plain TEST coda source with the shared Hero"): return false
	var geometry: CinderLevel = level.get_node_or_null("ActualProductionGeometry") as CinderLevel
	if not _expect(is_instance_valid(geometry) and geometry.scene_file_path == SCENE_PATH and geometry.hero == null and geometry.effects == null and geometry.shared_shell == null and not geometry.is_physics_processing() and not geometry.call("floor_bindings").is_empty(), "nested actual production geometry is deliberately unentered; no strict host terminal or encounter is represented"): return false
	var player: Dictionary = hero.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	if not _expect(not player.is_empty() and not local.is_empty() and local.local.is_empty() and not local.progress.completed and local.progress.contact_exit_id == "" and player.world_actions.clock_s == 0.0 and not FLOW_EXIT.has_point(Vector2(hero.global_position.x, hero.global_position.z)), "pristine actual TEST source has no earned local tuple and begins outside its explicit interface contact region"): return false
	var observation: Dictionary = _preview.call("get_input_observation_state")
	var anchor: Vector2 = _preview.call("get_aim_anchor_normalized")
	var camera: Camera3D = _preview.get("camera") as Camera3D
	_initial = {"schema_version": 1, "level_id": "A2-L5", "scene_path": FLOW_SCENE, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": player, "level": local, "shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": observation.sequence, "last_input_observation": observation.last_observation.duplicate(true), "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": _preview.get("_shake"), "difficulty_at_entry": "standard"}}
	var wire: String = Exact.stringify(_initial)
	var parsed: Dictionary = Exact.parse(wire)
	if not _expect(not wire.is_empty() and parsed.get("accepted", false) and Exact.stringify(parsed.value) == wire and level.snapshot_error_with_player(_initial.level, _initial.player).is_empty(), "actual TEST source tuple uses exact transport and public paired preflight without terminal seeds"): return false
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = PREFIX.duplicate() # TEST ONLY prior-prefix metadata.
	payload.story = {"kind": "story", "level_id": "A2-L5", "snapshot": _initial.duplicate(true), "checkpoint": _initial.duplicate(true)}
	if not _expect(model.state_error(payload).is_empty() and model.restore_session(payload), "public Attempts accepts representative prior prefix plus actual pristine TEST source"): return false
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	_initial_payload = model.state()
	if not _expect(store.write_payload(_initial_payload), "public validated Store writes isolated interface source payload: " + store.last_error): return false
	var refs: Array[Dictionary] = _refs(_preview, true)
	level.exit_level()
	_preview.free(); _preview = null
	return _expect(_refs_freed(refs), "whole standalone TEST constructor and unentered production geometry are retired before disk Continue")

func _flow_continue(saved: Dictionary, label: String) -> bool:
	_restore_events.clear(); _watch_restore = true
	_shell.menu.continue_story_requested.emit()
	await _settle()
	_watch_restore = false
	var actual: Dictionary = _shell.capture_campaign_snapshot()
	return _expect(paused and _shell.menu.page_name() == "resume" and _shell.campaign_error.is_empty() and _same(actual, saved) and _restore_events.is_empty() and _same(_shell.attempts.story_snapshot(), actual), "real disk Continue quietly installs exact " + label + ": " + _shell.campaign_error + str(_restore_events))

func _flow_transition() -> bool:
	var source: CinderLevel = _shell.active_level
	var hero: CinderPlayer = _shell.player
	source.completion_requested.connect(func(id: String, event: String) -> void: _flow_completed.append(id + ":" + event))
	source.contact_exit_requested.connect(func(id: String, event: String) -> void: _flow_exits.append(id + ":" + event))
	_shell.menu.resume_requested.emit()
	if not await _flow_ready(hero): return false
	if not _expect(not source.request_contact_exit(FLOW_EXIT_ID, hero) and _flow_exits.is_empty() and _shell.active_level == source and _shell.attempts.state().completed_main == PREFIX, "public contact exit refuses before actual TEST source completion"): return false
	if not _expect(source.request_completion(FLOW_COMPLETION_ID) and not source.request_completion(FLOW_COMPLETION_ID), "public completion accepts exactly once on the live TEST CinderLevel"): return false
	await _settle()
	if not _expect(_shell.campaign_error.is_empty() and _flow_completed == ["A2-L5:" + FLOW_COMPLETION_ID] and _flow_exits.is_empty() and _shell.active_level == source, "real Shell commits completion without requiring or manufacturing a contact exit"): return false
	_shell.request_pause()
	await _settle()
	var complete: Dictionary = _shell.capture_campaign_snapshot()
	var prefix: Array[String] = PREFIX.duplicate()
	prefix.append("A2-L5")
	if not _expect(not complete.is_empty() and complete.level.progress.completed and complete.level.progress.completion_id == FLOW_COMPLETION_ID and complete.level.progress.contact_exit_id == "" and _shell.attempts.state().completed_main == prefix and _same(_shell.attempts.state().story.checkpoint, _initial), "actual completion updates exactly the representative main prefix while protecting the original TEST entrance"): return false
	_shell.menu.resume_requested.emit()
	if not await _flow_ready(hero): return false
	if not _expect(not source.request_contact_exit(FLOW_EXIT_ID, source.get_node("ActualProductionGeometry")) and _flow_exits.is_empty(), "only the actual shared Hero may use the public completed contact exit"): return false
	# Real public resource changes, no saved/live HP or ammo assignments.
	var hp_before: float = hero.hp
	var shells_before: int = hero.shells
	hero.take_damage(7.0, Vector3.ZERO)
	var primary_hits: int = hero.slash(Vector3.LEFT)
	var blast_hits: int = hero.blast(Vector3.LEFT)
	if not _expect(not hero.dead and hero.hp < hp_before and hero.shells == shells_before - 1 and primary_hits == 0 and blast_hits == 0 and _flow_exits.is_empty() and _shell.active_level == source, "actual public shared hurt and combat taps change resources without impersonating a contact exit"): return false
	if not await _flow_ready(hero): return false
	var sequence: int = _flow_last_sequence(hero)
	if not _expect(hero.request_dash(Vector3.FORWARD), "real controller dash traverses permanent native coda floor toward the explicit TEST interface contact"): return false
	var completed_dash: bool = false
	for _index: int in range(FLOW_MAX_TICKS):
		await _probe.tick_finished
		if _flow_last_sequence(hero) > sequence and bool(hero.get_threat_response_state().stable):
			completed_dash = true
			break
	if not _expect(completed_dash, "actual controller publishes a completed dash and regains native support before interface contact"): return false
	var record: Dictionary = hero.get_world_action_records()[-1]
	if not _expect(record.kind == "dash" and not record.blocked and not record.collision_shortened and FLOW_EXIT.has_point(Vector2(hero.global_position.x, hero.global_position.z)) and record.landing == hero.global_position, "actual completed physical dash landing lies inside the authored TEST contact region"): return false
	_shell.request_pause() # Supported paused deferred boundary for actual Player capture.
	await _settle()
	if not _expect(paused and _shell.campaign_error.is_empty() and _shell.active_level == source and record.landing == hero.global_position, "public Pause preserves the real completed contact landing before exact resource capture"): return false
	var before_exit: Dictionary = hero.snapshot_state()
	if not _expect(not before_exit.is_empty() and before_exit.resources.hp < before_exit.resources.max_hp and before_exit.resources.shells < before_exit.resources.max_shells and before_exit.clocks.reload_s > 0.0, "actual source retains reduced HP/ammo and a genuine partial reload at its final native boundary"): return false
	var old_refs: Array[Dictionary] = _refs(_shell, false)
	var source_ref: WeakRef = weakref(source)
	var hero_ref: WeakRef = weakref(hero)
	if not _expect(source.request_contact_exit(FLOW_EXIT_ID, hero) and not source.request_contact_exit(FLOW_EXIT_ID, hero), "public physical Hero contact accepts once and latches duplicate refusal"): return false
	await _settle()
	if not _expect(paused and _shell.menu.page_name() == "resume" and _shell.campaign_error.is_empty() and _shell.active_level.level_id == "A3-L1" and _shell.active_level.scene_file_path == FLOW_DESTINATION and _flow_exits == ["A2-L5:" + FLOW_EXIT_ID] and _flow_completed == ["A2-L5:" + FLOW_COMPLETION_ID], "real Shell installs the actual canonical accepted A3-L1 after one TEST completion/contact transaction"): return false
	if not _expect(source_ref.get_ref() == null and hero_ref.get_ref() == null and _refs_freed(old_refs), "transition permanently frees the old source Hero, native coda floors/scenery and all original world descendants"): return false
	var arrived: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(not arrived.is_empty() and arrived.level.local.sources.size() == 5 and arrived.level.local.route.entries.is_empty() and arrived.level.local.route.deaths.is_empty() and arrived.level.local.scheduler.clock_s == 0.0 and arrived.player.world_actions.clock_s == 0.0 and not arrived.level.progress.completed and arrived.level.progress.contact_exit_id == "", "actual fresh A3-L1 contains its full five-source native packet with no invented entry/admission/defeat/completion"): return false
	_expect(arrived.player.resources.hp == before_exit.resources.hp and arrived.player.resources.shells == before_exit.resources.shells and arrived.player.clocks.reload_s == before_exit.clocks.reload_s and _same(arrived.equipment_ids, before_exit.equipment) and arrived.player.presentation.id == LabSprite.presentation_for_act(3) and Codec.read_vector3(arrived.player.motion.position) == _shell.active_level.spawn_position(), "actual transition carries exact source HP/ammo/partial reload/canonical gear and applies the Act3 presentation at its authored spawn")
	_expect(_shell.player.snapshot_error(arrived.player).is_empty() and _shell.active_level.snapshot_error_with_player(arrived.level, arrived.player).is_empty() and _shell.attempts.state().completed_main == prefix and _same(_shell.attempts.state().story.snapshot, arrived) and _same(_shell.attempts.state().story.checkpoint, arrived) and _shell.attempts.state().side_attempt == null, "public full A3-L1 paired preflight and complete Attempts state accept the installed fresh protected story unit")
	var disk: CinderSaveStore = Store.new(_test_root + "campaign.json")
	disk.payload_validator = _shell.attempts.saved_payload_error
	var stored: Dictionary = disk.read_payload()
	if not _expect(not stored.is_empty() and _same(stored, _shell.attempts.state()), "actual public durable Store exactly matches the transitioned complete Attempts payload"): return false
	var fresh_refs: Array[Dictionary] = _refs(_shell, true)
	_release_shell()
	if not _expect(_refs_freed(fresh_refs), "whole canonical A3-L1/Shell subtree is disposed before independent disk Continue"): return false
	if not await _new_shell() or not await _flow_continue(arrived, "canonical A3-L1 recipient"): return false
	_expect(_shell.active_level.scene_file_path == FLOW_DESTINATION and _shell.attempts.state().completed_main == prefix and _flow_completed.size() == 1 and _flow_exits.size() == 1, "disk Continue keeps the actual A3 recipient and never replays prior TEST completion/contact")
	fresh_refs = _refs(_shell, true)
	_release_shell()
	return _expect(_refs_freed(fresh_refs), "final actual A3 recipient and campaign Shell are fully released") and _failures == 0

func _flow_last_sequence(hero: CinderPlayer) -> int:
	var records: Array[Dictionary] = hero.get_world_action_records()
	return 0 if records.is_empty() else int(records[-1].sequence)

func _flow_ready(hero: CinderPlayer) -> bool:
	for _index: int in range(FLOW_MAX_TICKS):
		await _probe.tick_finished
		var response: Dictionary = hero.get_threat_response_state()
		if not paused and not hero.dead and response.stable and response.motion.grounded and response.dash_cooldown_left_s == 0.0: return true
	return _expect(false, "bounded genuine native Hero support/dash readiness")

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
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_bytes, "isolated interface injection preserves actual canonical registry bytes")
	for path: String in _source_bytes: _expect(FileAccess.get_file_as_string(path) == _source_bytes[path], "frozen direct input remains unchanged during focused transition fixture: " + path)
	_cleanup_paths()
	Engine.max_fps = _old_fps
	AudioServer.set_bus_layout(_old_audio)
	print("A2-L5 Act3 transition interface smoke: %d checks, %d failures; actual pristine production entrance codec separately; real Shell/Attempts/public TEST completion/physical contact/canonical A3-L1 fresh recipient/exact resources/durable Continue/cleanup only; representative unearned prior prefix; NO strict production terminal/coda, boss defeat, whole route, recognizer, portrait, art or balance credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
