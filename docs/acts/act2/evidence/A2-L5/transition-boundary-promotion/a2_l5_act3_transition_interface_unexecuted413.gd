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
const FlowHost: Script = preload("res://scripts/acts/act2/dead_london.gd")
const FLOW_EXIT: Rect2 = FlowHost.EXIT_REGION
const FLOW_DESTINATION: String = "res://scenes/acts/act3/a3_l1.tscn"
const FLOW_COMPLETION_ID: String = "dead-london-discovery"
const FLOW_EXIT_ID: String = "dead-london-to-act3"
const FLOW_MAX_TICKS: int = 180
const FLOW_POINTER: int = 23
const FLOW_INPUTS: Array[String] = ["res://tests/acts/act2/a2_l5_loading_retry_smoke.gd", FLOW_SCENE, "res://scripts/game.gd", "res://scripts/ui/campaign_menu.gd", "res://scripts/campaign/attempts.gd", "res://scripts/campaign/save_store.gd", "res://scripts/campaign/registry.gd", "res://scripts/campaign/exact_json.gd", FLOW_DESTINATION, "res://scripts/acts/act3/twin_suns_level.gd", "res://scripts/acts/act3/twin_suns.gd", "res://scripts/acts/act3/sunbound_stalker.gd", "res://data/campaign/act3/a3_l1_encounters.json"]
# TEST-only observer uses the exact production Hero point/Y contact predicate.
# It never enters or writes the nested strict production host.
class FlowContactObserver:
	extends Node
	var source: CinderLevel
	var hero: CinderPlayer
	var region: Rect2
	var observed: Callable
	var armed: bool = false
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 115
	func _physics_process(_delta: float) -> void:
		if not armed or not is_instance_valid(source) or not is_instance_valid(hero) or hero.dead or not source.is_completed() or source.hero != hero: return
		var at: Vector3 = hero.global_position
		if at.y < -0.05 or at.y > 0.2 or not region.has_point(Vector2(at.x, at.z)): return
		armed = false
		observed.call(at, hero.get_world_action_clock())

var _flow_production: Dictionary = {}
var _flow_observer: FlowContactObserver
var _flow_contact_seen: bool = false
var _flow_contact_done: bool = false
var _flow_contact_at: Vector3 = Vector3.ZERO
var _flow_contact_clock: float = -1.0
var _flow_before_exit: Dictionary = {}
var _flow_after_exit: Dictionary = {}
var _flow_precontact_payload: Dictionary = {}
var _flow_old_refs: Array[Dictionary] = []
var _flow_release_at: Vector2 = Vector2.ZERO
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

func _flow_registry_isolated(registry: CinderCampaignRegistry, canonical: CinderCampaignRegistry) -> bool:
	for record: Dictionary in (JSON.parse_string(_registry_bytes) as Dictionary).levels:
		var actual: Dictionary = registry.entry(record.id)
		var expected: Dictionary = canonical.entry(record.id)
		if record.id == "A2-L5":
			for field: String in ["scene_path", "readiness", "accepted_commit", "api_revision"]:
				actual.erase(field); expected.erase(field)
		if not _same(actual, expected): return false
	return true

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
	if not _expect(registry.last_error.is_empty() and registry.main_route() == canonical.main_route() and registry.entry("A3-L1") == canonical.entry("A3-L1") and _flow_registry_isolated(registry, canonical), "only TEST L5 source scene/readiness differs; all canonical route and A3-L1 metadata remain exact"): return false
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
	if not _expect(FLOW_EXIT == Rect2(-2.7, -45.8, 5.4, 1.3), "TEST contact observer uses the exact actual production coda EXIT_REGION"): return false
	source.completion_requested.connect(func(id: String, event: String) -> void: _flow_completed.append(id + ":" + event))
	source.contact_exit_requested.connect(func(id: String, event: String) -> void: _flow_exits.append(id + ":" + event))
	if not _flow_resume_consumed("pristine source Resume"): return false
	if not await _flow_ready(hero): return false
	if not _expect(not source.request_contact_exit(FLOW_EXIT_ID, hero) and _flow_exits.is_empty() and _shell.active_level == source and _shell.attempts.state().completed_main == PREFIX, "public contact exit refuses before actual TEST source completion"): return false
	if not _expect(source.request_completion(FLOW_COMPLETION_ID) and not source.request_completion(FLOW_COMPLETION_ID), "public dead-london-discovery completion accepts exactly once on the live TEST source"): return false
	await _settle()
	if not _expect(_shell.campaign_error.is_empty() and _flow_completed == ["A2-L5:" + FLOW_COMPLETION_ID] and _flow_exits.is_empty() and _shell.active_level == source, "real Shell commits actual completion ID without manufacturing a contact exit"): return false
	_shell.request_pause()
	await _settle()
	var complete: Dictionary = _shell.capture_campaign_snapshot()
	var prefix: Array[String] = PREFIX.duplicate()
	prefix.append("A2-L5")
	var completed_payload: Dictionary = _shell.attempts.state()
	if not _expect(paused and not complete.is_empty() and complete.level.progress.completed and complete.level.progress.completion_id == FLOW_COMPLETION_ID and complete.level.progress.contact_exit_id == "" and completed_payload.completed_main == prefix and _same(completed_payload.story.snapshot, complete) and _same(completed_payload.story.checkpoint, _initial) and _same(_flow_disk("campaign.json"), completed_payload), "exact paused completed source unit, durable payload and progress retain the labelled prior prefix and protected pristine TEST checkpoint"): return false
	if not _flow_resume_consumed("completed source Resume"): return false
	if not await _flow_ready(hero): return false
	if not _expect(not source.request_contact_exit(FLOW_EXIT_ID, source.get_node("ActualProductionGeometry")) and _flow_exits.is_empty(), "another body cannot use the actual completed contact exit"): return false
	# Real routed completed approach swipes stop before the actual exit region.
	# Their release point, rather than world landing, becomes the actual aim anchor.
	var approach_count: int = 0
	while hero.global_position.z - float(hero.get_threat_response_state().stats.dash_distance) > FLOW_EXIT.end.y and approach_count < 8:
		if not await _flow_completed_swipe(hero): return false
		approach_count += 1
	if not _expect(approach_count > 0 and approach_count < 8 and not FLOW_EXIT.has_point(Vector2(hero.global_position.x, hero.global_position.z)) and hero.global_position.z > FLOW_EXIT.end.y and hero.global_position.z - float(hero.get_threat_response_state().stats.dash_distance) < FLOW_EXIT.end.y and not _shell.get_aim_anchor_normalized().is_equal_approx(Vector2(0.5, 0.5)), "genuine completed native swipes approach the actual coda exit and establish a noncentral carried release anchor"): return false
	# Public shared hurt/primary/blast are actual resource transactions.
	var hp_before: float = hero.hp
	var shells_before: int = hero.shells
	hero.take_damage(7.0, Vector3.ZERO)
	var primary_hits: int = hero.slash(Vector3.LEFT)
	var blast_hits: int = hero.blast(Vector3.LEFT)
	if not _expect(not hero.dead and hero.hp < hp_before and hero.shells == shells_before - 1 and primary_hits == 0 and blast_hits == 0 and _flow_exits.is_empty() and _shell.active_level == source, "actual shared hurt and combat controls reduce resources without impersonating contact"): return false
	if not await _flow_ready(hero): return false
	_flow_precontact_payload = _shell.attempts.state()
	_flow_observer = FlowContactObserver.new()
	_flow_observer.name = "TEST_ONLY_ActualCodaContactObserver"
	_flow_observer.source = source
	_flow_observer.hero = hero
	_flow_observer.region = FLOW_EXIT
	_flow_observer.observed = _flow_observed_contact
	_shell.world.add_child(_flow_observer)
	_flow_observer.armed = true
	var input_before: Dictionary = _shell.get_input_observation_state()
	var anchor_before: Vector2 = _shell.get_aim_anchor_normalized()
	# The real drag starts the dash. Keep its finger held across the transition;
	# the recipient overlay must consume its release without another action.
	if not _flow_swipe(hero, false): return false
	if not _expect(_flow_native_equal(_shell.get_input_observation_state(), input_before) and _shell.get_aim_anchor_normalized() == anchor_before and hero.get_committed_dash_state().active, "actual final pointer drag starts native dash without inventing a release observation or changing the saved anchor"): return false
	for _index: int in range(FLOW_MAX_TICKS):
		await _probe.tick_finished
		if _flow_contact_seen: break
	if not _expect(_flow_contact_seen, "one actual controller overlap satisfies the production exit point/Y predicate before any contact request"): return false
	await _settle()
	if not _expect(_flow_contact_done and not _flow_before_exit.is_empty() and not _flow_after_exit.is_empty(), "measured overlap reaches supported paused capture and public contact dispatch"): return false
	var before_exit: Dictionary = _flow_before_exit.player
	if not _expect(before_exit.resources.hp < before_exit.resources.max_hp and before_exit.resources.shells < before_exit.resources.max_shells and before_exit.clocks.reload_s > 0.0 and before_exit.world_actions.clock_s == _flow_contact_clock and Codec.read_vector3(before_exit.motion.position) == _flow_contact_at and FLOW_EXIT.has_point(Vector2(_flow_contact_at.x, _flow_contact_at.z)), "source capture retains actual contact position/clock and reduced HP/ammo/partial reload without synthetic final dash completion"): return false
	if not _expect(paused and _shell.menu.page_name() == "resume" and _shell.campaign_error.is_empty() and _shell.active_level.level_id == "A3-L1" and _shell.active_level.scene_file_path == FLOW_DESTINATION and _flow_exits == ["A2-L5:" + FLOW_EXIT_ID] and _flow_completed == ["A2-L5:" + FLOW_COMPLETION_ID], "real Shell installs canonical A3-L1 after one measured TEST completion/contact transaction"): return false
	if not _expect(_refs_freed(_flow_old_refs), "transition permanently frees every old donor Hero/geometry/actor/cue/consumer and TEST contact observer"): return false
	# Public Store's prior-generation backup is the actual latched L5 exit unit
	# written by Shell._record_live immediately before the new destination write.
	var exited_payload: Dictionary = _flow_precontact_payload.duplicate(true)
	exited_payload.story.snapshot = _flow_after_exit.duplicate(true)
	if not _expect(_same(_flow_disk("campaign.json.bak"), exited_payload) and _flow_after_exit.level.progress.completion_id == FLOW_COMPLETION_ID and _flow_after_exit.level.progress.contact_exit_id == FLOW_EXIT_ID and _same(exited_payload.story.checkpoint, _initial), "actual durable predecessor generation exactly preserves completed/contact source, progress and protected TEST checkpoint"): return false
	var arrived: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(not arrived.is_empty() and arrived.level.local.sources.size() == 5 and arrived.level.local.route.entries.is_empty() and arrived.level.local.route.deaths.is_empty() and arrived.level.local.scheduler.clock_s == 0.0 and arrived.player.world_actions.clock_s == 0.0 and not arrived.level.progress.completed and arrived.level.progress.contact_exit_id == "", "fresh canonical A3-L1 contains its actual five-source native packet with no invented admissions/defeat/completion"): return false
	if not _expect(arrived.player.resources.hp == before_exit.resources.hp and arrived.player.resources.shells == before_exit.resources.shells and arrived.player.clocks.reload_s == before_exit.clocks.reload_s and _same(arrived.equipment_ids, before_exit.equipment) and _same(arrived.shell.anchor_normalized, _flow_before_exit.shell.anchor_normalized) and _shell.get_aim_anchor_normalized() == anchor_before and arrived.player.presentation.id == LabSprite.presentation_for_act(3) and Codec.read_vector3(arrived.player.motion.position) == _shell.active_level.spawn_position(), "actual transition carries exact gear/HP/ammo/partial reload/swipe aim anchor without healing, and applies authored Act3 spawn/presentation"): return false
	if not _expect(_shell.player.snapshot_error(arrived.player).is_empty() and _shell.active_level.snapshot_error_with_player(arrived.level, arrived.player).is_empty() and _shell.attempts.state().completed_main == prefix and _shell.registry.is_unlocked("A3-L1", prefix) and _same(_shell.attempts.state().story.snapshot, arrived) and _same(_shell.attempts.state().story.checkpoint, arrived) and _shell.attempts.state().side_attempt == null and _same(_flow_disk("campaign.json"), _shell.attempts.state()), "full recipient paired preflight, preserved completion/unlock and durable fresh Attempts unit are exact"): return false
	if not _flow_transition_input_consumed(arrived): return false
	if not _flow_resume_consumed("actual A3 recipient Resume"): return false
	_shell.request_pause() # No native tick between consumed Resume and this Pause.
	await _settle()
	if not _expect(_same(_shell.capture_campaign_snapshot(), arrived), "consumed recipient Resume and immediate public Pause preserve the exact fresh destination before independent Continue"): return false
	var fresh_refs: Array[Dictionary] = _refs(_shell, true)
	_release_shell()
	if not _expect(_refs_freed(fresh_refs), "whole canonical A3-L1/Shell subtree retires before independent disk Continue"): return false
	if not await _new_shell() or not await _flow_continue(arrived, "canonical A3-L1 recipient"): return false
	if not _expect(_shell.active_level.scene_file_path == FLOW_DESTINATION and _shell.attempts.state().completed_main == prefix and _flow_completed.size() == 1 and _flow_exits.size() == 1 and _same(_flow_disk("campaign.json"), _shell.attempts.state()), "fresh disk Continue exactly retains the canonical recipient/completion and never repeats predecessor completion/contact"): return false
	fresh_refs = _refs(_shell, true)
	_release_shell()
	return _expect(_refs_freed(fresh_refs), "final actual A3 recipient and campaign Shell are fully released") and _failures == 0

func _flow_observed_contact(at: Vector3, clock: float) -> void:
	_flow_contact_seen = true
	_flow_contact_at = at
	_flow_contact_clock = clock
	_flow_old_refs = _refs(_shell, false)
	_shell.request_pause() # Supported deferred barrier; later same-tick consumers finish.
	_flow_dispatch_contact.call_deferred()

func _flow_dispatch_contact() -> void:
	_flow_diagnose_contact("before_original_guard")
	if not _expect(paused and not Engine.is_in_physics_frame() and is_instance_valid(_shell) and is_instance_valid(_shell.player) and _shell.active_level == _flow_observer.source and _shell.player == _flow_observer.hero and _shell.player.get_world_action_clock() == _flow_contact_clock and _shell.player.global_position == _flow_contact_at, "deferred public Pause retains the actual observed source/Hero/overlap without another native tick"): return
	_flow_before_exit = _shell.capture_campaign_snapshot()
	_flow_diagnose_contact("after_existing_capture")
	if not _expect(not _flow_before_exit.is_empty() and _flow_before_exit.level.progress.completed and _flow_before_exit.level.progress.contact_exit_id == "", "paused actual predecessor unit captures before the measured contact latch"): return
	var source: CinderLevel = _shell.active_level
	if not _expect(source.request_contact_exit(FLOW_EXIT_ID, _shell.player) and not source.request_contact_exit(FLOW_EXIT_ID, _shell.player), "public dead-london-to-act3 dispatch follows measured real overlap once, then refuses its duplicate"): return
	_flow_after_exit = _shell.capture_campaign_snapshot()
	_flow_contact_done = not _flow_after_exit.is_empty()

func _flow_diagnose_contact(point: String) -> void:
	# Passive ORIGINAL field/getter/error reporting. No capture, validator,
	# pause/control, wait, native motion or transport-state write occurs here.
	var shell_live: bool = is_instance_valid(_shell)
	var hero_live: bool = shell_live and is_instance_valid(_shell.player)
	var source_live: bool = shell_live and is_instance_valid(_shell.active_level)
	var observer_live: bool = is_instance_valid(_flow_observer)
	var facts: Dictionary = {"point": point, "paused": paused, "in_physics_frame": Engine.is_in_physics_frame(), "shell_live": shell_live, "hero_live": hero_live, "source_live": source_live, "observer_live": observer_live, "observed_clock_s": _flow_contact_clock, "observed_position": Codec.vector3(_flow_contact_at), "original_capture_empty": _flow_before_exit.is_empty()}
	facts["same_source"] = shell_live and observer_live and _shell.active_level == _flow_observer.source
	facts["same_hero"] = shell_live and observer_live and _shell.player == _flow_observer.hero
	facts["clock_matches_observation"] = hero_live and _shell.player.get_world_action_clock() == _flow_contact_clock
	facts["position_matches_observation"] = hero_live and _shell.player.global_position == _flow_contact_at
	facts["original_guard_conjunction"] = paused and not Engine.is_in_physics_frame() and shell_live and hero_live and facts.same_source and facts.same_hero and facts.clock_matches_observation and facts.position_matches_observation
	if shell_live:
		facts["shell_campaign_error"] = _shell.campaign_error
		facts["game_level_load_error"] = _shell.level_load_error
		facts["shell_draining"] = bool(_shell.get("_draining"))
		facts["shell_drain_queued"] = bool(_shell.get("_drain_queued"))
		facts["shell_pause_request_pending"] = _shell.is_pause_requested()
	if hero_live:
		facts["hero_clock_s"] = _shell.player.get_world_action_clock()
		facts["hero_position"] = Codec.vector3(_shell.player.global_position)
		facts["hero_dead"] = _shell.player.dead
		facts["hero_last_snapshot_error"] = _shell.player.last_snapshot_error
		facts["actual_position_in_exit"] = FLOW_EXIT.has_point(Vector2(_shell.player.global_position.x, _shell.player.global_position.z))
		facts["actual_y_in_contact_bounds"] = _shell.player.global_position.y >= -0.05 and _shell.player.global_position.y <= 0.2
	if source_live:
		facts["source_completed"] = _shell.active_level.is_completed()
		facts["source_last_snapshot_error"] = _shell.active_level.last_snapshot_error
	if not _flow_before_exit.is_empty():
		var progress: Dictionary = _flow_before_exit.get("level", {}).get("progress", {})
		facts["original_capture_progress"] = progress.duplicate(true)
		facts["original_capture_predicate"] = bool(progress.get("completed", false)) and progress.get("contact_exit_id", null) == ""
	# Every emitted member is a closed primitive/array/dictionary from the
	# original state; actual comparisons are retained as booleans, no Objects.
	print("FLOW_CONTACT_DIAGNOSTIC ", JSON.stringify(facts))

func _flow_disk(file: String) -> Dictionary:
	var store: CinderSaveStore = Store.new(_test_root + file)
	store.payload_validator = _shell.attempts.saved_payload_error
	return store.read_payload()

func _flow_resume_consumed(note: String) -> bool:
	if not _expect(paused and _shell.menu.is_open(), note + ": real overlay is paused/open"): return false
	var button: Control = _shell.menu.find_child("ResumeButton", true, false) as Control
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree(), note + ": real ResumeButton is visible"): return false
	var history: Array[Dictionary] = _shell.player.get_world_action_records()
	var observer: Dictionary = _shell.get_input_observation_state()
	var clock: float = _shell.player.get_world_action_clock()
	var hp: float = _shell.player.hp
	var shells: int = _shell.player.shells
	var at: Vector3 = _shell.player.global_position
	var anchor: Vector2 = _shell.get_aim_anchor_normalized()
	var pixel: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = pixel; motion.global_position = pixel
	root.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = pixel; down.global_position = pixel; down.pressed = true
	root.push_input(down, true)
	var down_handled: bool = root.is_input_handled()
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up, true)
	return _expect(down_handled and root.is_input_handled() and not paused and not _shell.menu.is_open() and _flow_native_equal(_shell.get_input_observation_state(), observer) and _flow_native_equal(_shell.player.get_world_action_records(), history) and _shell.player.get_world_action_clock() == clock and _shell.player.hp == hp and _shell.player.shells == shells and _shell.player.global_position == at and _shell.get_aim_anchor_normalized() == anchor, note + ": actual routed Resume press/release is consumed with no action, movement, input publication, clock advance or refill")

func _flow_swipe(hero: CinderPlayer, release: bool) -> bool:
	var right: Vector3 = _shell.camera.global_basis.x; right.y = 0.0
	var down: Vector3 = _shell.camera.global_basis.z; down.y = 0.0
	var delta: Vector2 = Vector2(Vector3.FORWARD.dot(right.normalized()), Vector3.FORWARD.dot(down.normalized())) * 160.0
	var start: Vector2 = root.get_visible_rect().size * Vector2(0.5, 0.6)
	_flow_release_at = start + delta
	if not _expect(not paused and hero == _shell.player and _shell.screen_to_direction(delta).is_equal_approx(Vector3.FORWARD), "actual camera maps routed swipe to the intended physical forward controller dash"): return false
	var input_before: Dictionary = _shell.get_input_observation_state()
	var touch := InputEventScreenTouch.new()
	touch.index = FLOW_POINTER; touch.position = start; touch.pressed = true
	root.push_input(touch, true)
	var drag := InputEventScreenDrag.new()
	drag.index = FLOW_POINTER; drag.position = _flow_release_at; drag.relative = delta
	root.push_input(drag, true)
	if not _expect(hero.get_committed_dash_state().active, "actual routed drag commits the shared native dash"): return false
	if release:
		touch.position = _flow_release_at; touch.pressed = false
		root.push_input(touch, true)
		var observed: Dictionary = _shell.get_input_observation_state()
		return _expect(observed.sequence == input_before.sequence + 1 and observed.last_observation.kind == "swipe_release" and _shell.get_aim_anchor_normalized() == _flow_release_at / root.get_visible_rect().size, "actual routed swipe release publishes its exact screen aim anchor")
	return true

func _flow_completed_swipe(hero: CinderPlayer) -> bool:
	var sequence: int = _flow_last_sequence(hero)
	if not _flow_swipe(hero, true): return false
	for _index: int in range(FLOW_MAX_TICKS):
		await _probe.tick_finished
		if _flow_last_sequence(hero) > sequence and bool(hero.get_threat_response_state().stable):
			var record: Dictionary = hero.get_world_action_records()[-1]
			if not _expect(record.kind == "dash" and not record.blocked and not record.collision_shortened and record.landing == hero.global_position and not FLOW_EXIT.has_point(Vector2(hero.global_position.x, hero.global_position.z)), "real completed approach dash has native support and remains outside actual coda contact"): return false
			return await _flow_ready(hero)
	return _expect(false, "bounded actual completed approach swipe publication")

func _flow_transition_input_consumed(arrived: Dictionary) -> bool:
	var observer: Dictionary = _shell.get_input_observation_state()
	var history: Array[Dictionary] = _shell.player.get_world_action_records()
	var payload: Dictionary = _shell.attempts.state()
	var release := InputEventScreenTouch.new()
	release.index = FLOW_POINTER; release.position = _flow_release_at; release.pressed = false
	root.push_input(release, true)
	return _expect(paused and _shell.menu.is_open() and _same(_shell.capture_campaign_snapshot(), arrived) and _flow_native_equal(_shell.get_input_observation_state(), observer) and _flow_native_equal(_shell.player.get_world_action_records(), history) and _same(_shell.attempts.state(), payload) and _same(_flow_disk("campaign.json"), payload), "actual held predecessor pointer release is consumed by recipient overlay without movement/attack/input history/resource/durable drift")

func _flow_native_equal(left: Variant, right: Variant) -> bool:
	# Native public observations contain Vector2/Vector3; Exact JSON accepts
	# only portable transport. Compare their original types/values directly.
	if typeof(left) != typeof(right): return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _flow_native_equal(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _flow_native_equal(left[index], right[index]): return false
		return true
	return left == right

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
	print("A2-L5 Act3 transition interface smoke: %d checks, %d failures; actual pristine production entrance codec separately; real Shell/Attempts/actual IDs/TEST measured production-region contact/canonical A3-L1 fresh recipient/exact resources+aim/menu consumption/durable Continue/cleanup only; representative unearned prior prefix; NO strict production terminal/coda, boss defeat, whole route, recognizer, portrait, art or balance credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
