extends "res://tests/acts/act1/a1_l3_normal_full_route.gd"
## PRIVATE, unparsed/unexecuted candidate fixture. Requires reviewed promotion
## of full-parent843 + Actor constructor + RouteCodec537 + opt-in + Shared34.
## Existing TEST predecessor handoffs/accepted metadata are setup, not L1/L2
## play/production acceptance. Only umbrella->breathing is earned by input.
## No Player/actor HP/ammo/body/phase/clock/progress seeding or solver substitute.

const AggregateShell = preload("res://scripts/campaign/shell.gd")
const AggregateRegistry = preload("res://scripts/campaign/registry.gd")
const AggregateScene: String = "res://scenes/acts/act1/a1_l3_full.tscn" # Proposed promotion.
const AggregateScript: String = "res://scripts/acts/act1/mushroom_caverns_full.gd"
const ExpectedCandidateSHA: String = "e6669c37647542b6225dbcfabd4e2ec99a4085bf77e3d8ef1b757fdf176956d5"
const AggregateWallMs: int = 600000 # One real prefix +19-recipient validation, ten min.
const AggregateLocalKeys: Array[String] = ["authored_snapshot_version", "beat_index", "completed_beats", "room_stage", "actors", "scheduler", "fields", "consumers", "framing"]
var aggregate_root: String = ""
var aggregate_raw: Dictionary = {}
var aggregate_registry_text: String = ""
var aggregate_old_fps: int = 0
var aggregate_old_audio: AudioBusLayout
var aggregate_fresh: CinderCampaignShell
var aggregate_candidate: Dictionary = {}
var aggregate_pending_checkpoint: bool = false
var aggregate_boundary_busy: bool = false
var aggregate_checkpoint: Dictionary = {}
var aggregate_saved: Dictionary = {}
var aggregate_receipts: Array[Dictionary] = []
var aggregate_quiet_events: int = 0
var aggregate_earlier_wire: String = ""


func _initialize() -> void:
	aggregate_old_fps = Engine.max_fps
	aggregate_old_audio = AudioServer.generate_bus_layout()
	aggregate_root = "user://test-l3-native-aggregate-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_aggregate_poll_checkpoint)
	super._initialize()


func _shell() -> CinderCampaignShell:
	return game as CinderCampaignShell


func _run() -> void:
	portrait = false # Selected native/headless save scope; no new portrait claim.
	root.size = PortraitSize
	if not _require(ResourceLoader.exists(AggregateScene) and FileAccess.file_exists(AggregateScript) and FileAccess.get_file_as_string(AggregateScript).sha256_text() == ExpectedCandidateSHA, "fixture explicitly requires promoted exact full-parent843; never substitute save-denied scaffold"):
		await _finish(); return
	if not await _aggregate_start(): await _finish(); return
	var pristine: Dictionary = _shell().capture_campaign_snapshot()
	if not _require(not pristine.is_empty() and _local_closed(pristine.level.local) and pristine.level.local.beat_index == 0 and pristine.level.local.room_stage == "approach" and pristine.level.local.completed_beats.is_empty() and pristine.level.local.framing.is_empty() and pristine.level.local.scheduler.reservations.is_empty() and pristine.level.local.scheduler.profile.is_empty(), "real initial whole aggregate has exact nine local roots/pristine19/empty native encounter"):
		await _finish(); return
	if not _future_pristine([], "fresh full aggregate") or not _durable_exact(_shell()) or not await _gui_resume_pair(): await _finish(); return
	process_frame.connect(_sample_opening)
	process_frame.connect(_sample_crowd)
	physics_frame.connect(_full_phase_observer)
	if not await _full_enter_room(0) or not await _full_clear_room(0) or not await _full_room_boundary(0):
		_full_diagnostic("aggregate genuine first clear failed"); await _finish(); return
	if not await _aggregate_settle_checkpoint(): await _finish(); return
	aggregate_checkpoint = _shell().attempts.state().story.checkpoint.duplicate(true)
	aggregate_earlier_wire = Exact.stringify(aggregate_checkpoint)
	if not _require(not aggregate_earlier_wire.is_empty() and aggregate_checkpoint.level.local.beat_index == 1 and aggregate_checkpoint.level.local.room_stage == "approach" and aggregate_checkpoint.level.progress.checkpoint_id == "umbrella-grove" and aggregate_checkpoint.level.local.completed_beats == ["umbrella-grove"], "protected earlier checkpoint is the real three-ordinary-defeat boundary, not a fabricated prior route"):
		await _finish(); return
	if not await _full_enter_room(1): await _finish(); return
	if not await _wait(func() -> bool: return not _fresh_warning().is_empty(), "actual breathing fresh native warning before save", 12.0): await _finish(); return
	var id: String = _fresh_warning()
	var actual: Dictionary = sources[id].call("pure_presentation_state")
	full_pause_target = {"id": id, "lease": actual.reservation_id, "cycle": actual.cycle, "phase": "warning"}
	full_pause_requested = false
	_full_phase_observer() # Actual public deferred pause; never seed phase/sample.
	if not await _wait(func() -> bool: return _full_phase_pause_reached(id, "warning"), "whole native warning save barrier", 8.0, true) or not await _aggregate_settle(): await _finish(); return
	# The pause acknowledgement alone cannot certify the requested phase.
	# Read the ACTUAL stopped whole-tick presentation/native lease before capture;
	# Actor transport has no synthetic phase/status keys to seed or infer here.
	var paused_source: Dictionary = sources[id].call("pure_presentation_state")
	var paused_native: Dictionary = scheduler.reservation_state(actual.reservation_id)
	if not _require(paused and paused_source.phase == "warning" and paused_source.status == "running" and paused_source.reservation_id == actual.reservation_id and paused_source.cycle == actual.cycle and not paused_native.is_empty() and paused_native.state == "warning", "selected whole-tick save barrier retains the ACTUAL Warning/running presentation and exact observed cycle/lease"):
		await _finish(); return
	full_pause_target.clear(); full_pause_requested = false
	aggregate_saved = _shell().capture_campaign_snapshot()
	if not _require(not aggregate_saved.is_empty() and _local_closed(aggregate_saved.level.local) and aggregate_saved.level.local.beat_index == 1 and aggregate_saved.level.local.room_stage == "active" and aggregate_saved.level.local.completed_beats == ["umbrella-grove"] and aggregate_saved.level.local.framing.has(id) and aggregate_saved.level.local.actors[id].reservation_id == actual.reservation_id and aggregate_saved.level.local.actors[id].cycle == paused_source.cycle and aggregate_saved.level.local.fields.breathing != null and aggregate_saved.level.local.consumers.breathing != null and aggregate_saved.level.local.fields["crossed-left"] == null and aggregate_saved.level.local.fields.court == null and aggregate_saved.player.resources.hp == initial_hp and hit_events.is_empty() and Exact.stringify(_shell().attempts.state().story.checkpoint) == aggregate_earlier_wire and _durable_exact(_shell()), "genuine later native lease saves exact living/bound breathing pair, prior dead room and future dormant13 while preserving earlier checkpoint"):
		await _finish(); return
	aggregate_receipts.append({"stage": "selected actual whole-tick Warning save", "source_id": id, "phase": paused_source.phase, "status": paused_source.status, "cycle": paused_source.cycle, "reservation_id": paused_source.reservation_id, "native_lease": _portable(paused_native), "whole_snapshot_sha256": Exact.stringify(aggregate_saved).sha256_text()})
	var wire: String = Exact.stringify(aggregate_saved)
	var before: Dictionary = _donor_receipt()
	var until: int = Time.get_ticks_msec() + 100
	while Time.get_ticks_msec() < until and not finishing: await process_frame
	if not _require(_donor_receipt() == before and Exact.stringify(_shell().capture_campaign_snapshot()) == wire, "paused whole aggregate freezes exact actor/Player/Scheduler/environment/UI/attempt/disk without events"):
		await _finish(); return
	if not _malformed_rejection(id) or not _direct_native_candidate(): await _finish(); return
	if not await _fresh_title_continue(wire, before): await _finish(); return
	# Fresh independent shell is disposed before public Retry changes this donor.
	var donor_ids: Dictionary = _identities(_shell())
	_full_disconnect_observers()
	if process_frame.is_connected(_sample_opening): process_frame.disconnect(_sample_opening)
	if process_frame.is_connected(_sample_crowd): process_frame.disconnect(_sample_crowd)
	if physics_frame.is_connected(_full_phase_observer): physics_frame.disconnect(_full_phase_observer)
	_shell().request_retry()
	if not await _aggregate_settle(): await _finish(); return
	if not _require(_shell().campaign_error.is_empty() and paused and _shell().menu.page_name() == "resume" and Exact.stringify(_shell().capture_campaign_snapshot()) == aggregate_earlier_wire and _identities(_shell()) != donor_ids and Exact.stringify(_shell().attempts.state().story.checkpoint) == aggregate_earlier_wire and _durable_exact(_shell()), "actual protected Retry installs earlier native prefix after quiet optical gate without HP/ammo refill or checkpoint overwrite"):
		await _finish(); return
	var retry: Dictionary = _shell().capture_campaign_snapshot()
	if not _require(retry.player.resources == aggregate_checkpoint.player.resources and retry.level.local.fields.breathing == null and retry.level.local.consumers.breathing == null and retry.level.local.framing.is_empty() and not retry.level.progress.completed and _shell().attempts.state().completed_main == ["A1-L1", "A1-L2"], "Retry has earlier genuine resources/three dead/16 dormant, no future field or L3 completion"):
		await _finish(); return
	if not _all_bindings_actual(_shell()): await _finish(); return
	aggregate_receipts.append({"scope": "actual native prefix only", "saved_exact_json": wire, "protected_checkpoint_exact_json": aggregate_earlier_wire, "real_swipes": swipes, "real_ordinary_primaries": primaries, "actual_signal_world_actions": _portable(world_records), "actual_input_observations": _portable(input_observations)})
	await _finish()


func _aggregate_start() -> bool:
	# Make this a genuine coroutine before native scene creation; inherited async
	# compatibility issue is not repaired by moving the real Hero after creation.
	await process_frame
	aggregate_registry_text = FileAccess.get_file_as_string(AggregateRegistry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(aggregate_registry_text)
	if not _require(parsed is Dictionary and parsed.get("levels") is Array, "canonical registry supplies isolated TEST metadata"): return false
	aggregate_raw = parsed.duplicate(true)
	for entry: Dictionary in aggregate_raw.levels:
		if entry.id in ["A1-L1", "A1-L2", "A1-L3"]:
			entry.scene_path = AggregateScene if entry.id == "A1-L3" else "res://tests/fixtures/campaign/live_%s.tscn" % String(entry.id).to_lower().replace("-", "_")
			entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40)
			entry.api_revision = AggregateRegistry.API_REVISION
	game = _new_native_shell()
	if game == null or not await _aggregate_settle(): return false
	if not _require(paused and _shell().player == null and _shell().active_level == null and _shell().menu.page_name() == "title", "actual isolated Title begins with no installed Hero"): return false
	if not _select_standard() or not _press_menu(_shell(), "JourneyButton") or not await _aggregate_settle(): return false
	_shell().menu.select_level("A1-L1")
	if not _press_menu(_shell(), "LevelCardAction") or not await _aggregate_settle(): return false
	for predecessor: String in ["A1-L1", "A1-L2"]:
		if not _require(_shell().active_level.level_id == predecessor and _shell().active_level.scene_file_path == ("res://tests/fixtures/campaign/live_%s.tscn" % predecessor.to_lower().replace("-", "_")), "only disclosed existing TEST predecessor handoff is installed: " + predecessor): return false
		if not _require(_shell().active_level.request_completion("test-l3-entry-" + predecessor), "TEST predecessor public completion is setup only"): return false
		if not await _aggregate_settle(): return false
		if not _require(_shell().active_level.request_contact_exit("test-l3-entry-contact", _shell().player), "TEST predecessor public same-Hero contact is setup only"): return false
		if not await _aggregate_settle(): return false
	current_scope = "native-full-aggregate-prefix"
	level = _shell().active_level; hero = _shell().player
	scheduler = level.get("scheduler") as CinderThreatScheduler if level != null else null
	if not _require(level != null and hero != null and scheduler != null and paused and level.scene_file_path == AggregateScene and level.get_script().resource_path == AggregateScript and level.hero == hero and hero.global_position == FullLayout.SPAWN and _shell().campaign_error.is_empty() and _shell().get_difficulty_preference() == "standard", "real Shell installs exact full-parent/one Hero at genuine spawn with Standard starter resources"): return false
	sources = (level.get("sources") as Dictionary).duplicate(); initial_hp = hero.hp
	full_spec = level.call("normal_route_spec")
	if not _require(full_spec.sources == NormalIds and Codec.keys_error(sources, NormalIds).is_empty() and hero.equipment.snapshot() == {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"} and hero.get_world_action_records().is_empty() and _shell().attempts.state().completed_main == ["A1-L1", "A1-L2"], "all nineteen actual native actors exist; only TEST predecessors complete and no input has been invented"): return false
	for id: String in NormalIds:
		var actor: CharacterBody3D = sources[id]
		var body := actor.get_node_or_null("BodyCollision") as CollisionShape3D
		var native: Dictionary = actor.call("get_spore_native_bindings")
		if not _require(body != null and body.shape is CapsuleShape3D and native.player == hero and native.scheduler == scheduler, "actual same-world native configuration/capsule aliases: " + id): return false
		opening_references[id] = {"actor": actor, "body": body, "shape": body.shape, "art": actor.call("get_art"), "cue": actor.call("get_cue"), "configuration": native.configuration.duplicate(true)}
		opening_activation_counts[id] = 0; opening_dormancy[id] = true
		approach_displacement[id] = 0.0; full_defeats[id] = 0
		actor.connect("state_changed", Callable(self, "_notice_phase").bind(id))
		actor.connect("hit_resolved", Callable(self, "_notice_hit").bind(id))
		actor.connect("defeated", _full_notice_defeat)
		(actor.call("get_cue") as CinderThreatCue).state_changed.connect(func(_state: Dictionary) -> void: events += 1)
	level.connect("native_admission_published", _notice_admission)
	level.checkpoint_requested.connect(_notice_checkpoint)
	level.completion_requested.connect(func(_id: String, _key: String) -> void: opening_completion_events += 1)
	level.contact_exit_requested.connect(func(_id: String, _key: String) -> void: opening_contact_events += 1)
	hero.world_action_executed.connect(func(record: Dictionary) -> void: world_records.append(record.duplicate(true)); events += 1)
	game.connect("input_observed", func(observation: Dictionary) -> void: input_observations.append(observation.duplicate(true)))
	return _future_pristine([], "native initial aggregate") and _environment_absent() and _all_bindings_actual(_shell())


func _new_native_shell() -> CinderCampaignShell:
	var shell: CinderCampaignShell = AggregateShell.new()
	if not _require(shell.configure_runtime(aggregate_raw, aggregate_root + "campaign.json", aggregate_root + "settings.json", aggregate_root + "preferences.json"), "native Shell uses its canonical model/format2 and unique fixture paths"):
		shell.free(); return null
	root.add_child(shell)
	return shell


func _select_standard() -> bool:
	if not _press_menu(_shell(), "SettingsButton"): return false
	var selector := _shell().menu.find_child("DifficultySelector", true, false) as OptionButton
	if not _require(selector != null and _shell().menu.page_name() == "settings", "actual Settings exposes profile selector"): return false
	var selected: bool = false
	for i: int in range(selector.item_count):
		if selector.get_item_metadata(i) == "standard":
			selector.select(i); selector.item_selected.emit(i); selected = true; break
	return _require(selected and _shell().get_difficulty_preference() == "standard", "actual public profile selection is Standard") and _press_menu(_shell(), "BackButton")


func _press_menu(shell: CinderCampaignShell, name: String) -> bool:
	var button := shell.menu.find_child(name, true, false) as Button
	if not _require(button != null and button.is_visible_in_tree() and not button.disabled, "real native menu has enabled " + name): return false
	button.pressed.emit() # Public setup/menu command only, never gameplay input.
	return true


func _aggregate_settle() -> bool:
	for frame: int in range(8):
		if finishing or aborted: return false
		await process_frame
	return _require(is_instance_valid(game) and _shell().campaign_error.is_empty(), "actual campaign queue drains without error: " + (_shell().campaign_error if is_instance_valid(game) else "Shell absent"))


func _notice_checkpoint(id: String, checkpoint: String, kind: String) -> void:
	super._notice_checkpoint(id, checkpoint, kind)
	aggregate_pending_checkpoint = true


func _aggregate_poll_checkpoint() -> void:
	if finishing or aborted or aggregate_boundary_busy or not aggregate_pending_checkpoint: return
	aggregate_boundary_busy = true
	_aggregate_service_checkpoint.call_deferred()


func _aggregate_service_checkpoint() -> void:
	if not await _aggregate_settle(): aggregate_boundary_busy = false; return
	var saved: Dictionary = _shell().attempts.state().story.checkpoint
	if not _require(saved.level_id == "A1-L3" and saved.level.progress.checkpoint_id == "umbrella-grove" and _durable_exact(_shell()), "real automatic first checkpoint saves the native whole unit in format2"):
		aggregate_boundary_busy = false; return
	if paused:
		if not _require(_shell().menu.page_name() == "resume", "only observed checkpoint Resume may receive automatic fixture GUI input") or not await _gui_resume_pair(): aggregate_boundary_busy = false; return
	aggregate_pending_checkpoint = false; aggregate_boundary_busy = false


func _aggregate_settle_checkpoint() -> bool:
	var deadline: int = Time.get_ticks_msec() + 8000
	while aggregate_pending_checkpoint or aggregate_boundary_busy:
		if finishing or aborted or Time.get_ticks_msec() > deadline: return _require(false, "observed native checkpoint drain is bounded")
		await process_frame
	return true


func _guard_input() -> bool:
	if aborted or finishing or not is_instance_valid(hero) or hero.dead: return false
	if aggregate_pending_checkpoint:
		return _require_unexpected(not paused or not _shell().menu.is_open() or _shell().menu.page_name() == "resume", "only genuine checkpoint transition permits a temporary input-read guard; no focus/Pause resume")
	return super._guard_input()


func _ready_input(label: String) -> bool:
	if not await _aggregate_settle_checkpoint(): return false
	return await super._ready_input(label)


func _resume_button(surface: Node) -> Button:
	if surface == null: return null
	var button := surface.find_child("ResumeButton", true, false) as Button
	return button if button != null and not button.disabled and button.is_visible_in_tree() else null


func _gui_resume_pair() -> bool:
	if not _require(paused and _shell().menu.page_name() in ["pause", "resume"], "actual CampaignMenu has the entitled public Resume surface"): return false
	var button: Button = _resume_button(_shell().menu)
	if not _require(button != null, "native menu Resume is visible"): return false
	var before: Dictionary = game.call("get_input_observation_state")
	var records: Array[Dictionary] = hero.get_world_action_records()
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press); await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release); await process_frame
	return _require(not paused and game.call("get_input_observation_state") == before and hero.get_world_action_records() == records, "actual GUI Resume consumes both events without movement/primary/release-anchor change")


func _full_pause(label: String) -> bool:
	if not await _aggregate_settle_checkpoint(): return false
	if not paused and not _require(game.call("request_pause_deferred"), label + " requests one public whole-tick pause"): return false
	if not await _wait(func() -> bool: return paused, label + " reaches paused native boundary", 2.0, true) or not await _aggregate_settle(): return false
	return _require(_shell().menu.page_name() in ["pause", "resume"] and _resume_button(_shell().menu) != null, "native CampaignMenu exposes Resume after its canonical save drain")


func _full_quiet_capture(stage: String) -> bool:
	# Preserve the original checkpoint service before this SINGLE2 native window.
	# CampaignShell settles its save queue and exposes CampaignMenu, not HUD Pause.
	if not await _aggregate_settle_checkpoint(): return false
	# A Dictionary is captured by reference; one real deferred request only.
	var observation: Dictionary = {"requested": false}
	if not await _wait(func() -> bool:
		if not _require_unexpected(is_instance_valid(game) and game is CinderCampaignShell and is_instance_valid(hero) and not hero.dead, stage + " retains the actual CampaignShell and living Hero during capture observation"): return false
		if paused:
			if not _require_unexpected(observation.requested, stage + " unexpected focus/pause before the requested capture stops observation"): return false
			return _aggregate_capture_menu_ready()
		if not _guard_input(): return false
		if observation.requested or not _full_capture_view_ready(): return false
		observation.requested = bool(game.call("request_pause_deferred"))
		_require_unexpected(observation.requested, stage + " requests one actual deferred pause after complete current view readiness")
		return false, stage + " reaches complete current framing and the actual CampaignMenu pause boundary", 2.0, true): return false
	# Retain the original eight-frame canonical save-settlement hook. Capture has
	# its own unchanged settlement/purity hook; neither starts another native wait.
	if not await _aggregate_settle(): return false
	if not _require(_aggregate_capture_menu_ready(), "native CampaignMenu exposes Resume after its canonical save drain"): return false
	if not _framing(stage) or not await _capture(stage): return false
	return await _gui_resume_pair()


func _aggregate_capture_menu_ready() -> bool:
	# Public, read-only menu observation; no HUD/menu/renderer visibility write.
	if not is_instance_valid(game) or not game is CinderCampaignShell: return false
	var menu: Variant = _shell().menu
	return is_instance_valid(menu) and menu is CinderCampaignMenu and menu.is_open() and menu.page_name() in ["pause", "resume"] and _resume_button(menu) != null


func _capture(stage: String) -> bool:
	if not await _aggregate_settle(): return false
	var saved: Dictionary = _shell().capture_campaign_snapshot()
	if not _require(paused and not saved.is_empty() and _local_closed(saved.level.local), stage + " captures the real native whole aggregate instead of scaffold refusal"): return false
	aggregate_receipts.append({"stage": stage, "snapshot_sha256": Exact.stringify(saved).sha256_text(), "beat": saved.level.local.beat_index, "room_stage": saved.level.local.room_stage, "source_count": saved.level.local.actors.size(), "lease_source_ids": saved.level.local.framing.keys()})
	return true # no renderer, camera, cue or HUD visibility write


func _local_closed(local: Dictionary) -> bool:
	return Codec.keys_error(local, AggregateLocalKeys).is_empty() and local.authored_snapshot_version == 1 and Codec.keys_error(local.actors, NormalIds).is_empty()


func _malformed_rejection(id: String) -> bool:
	var bad: Dictionary = aggregate_saved.duplicate(true)
	bad.level.local.actors[id].reservation_id += "-foreign"
	if not _reject_same_donor(bad, "foreign native source lease"): return false
	bad = aggregate_saved.duplicate(true); bad.level.local.scheduler.clock_s += .5
	if not _reject_same_donor(bad, "cross-forged native sample/Scheduler clock"): return false
	bad = aggregate_saved.duplicate(true); bad.level.local.actors["umbrella-1"].hp = 1.0
	if not _reject_same_donor(bad, "required earlier defeated native source cannot gain HP"): return false
	bad = aggregate_saved.duplicate(true); bad.level.local.actors["court-1"].dormant = false
	if not _reject_same_donor(bad, "future court actor cannot be activated by transport"): return false
	bad = aggregate_saved.duplicate(true); bad.level.local.completed_beats.append("breathing-chamber")
	return _reject_same_donor(bad, "unearned room prefix cannot create constructors/checkpoints")


func _reject_same_donor(bad: Dictionary, label: String) -> bool:
	var before: Dictionary = _donor_receipt()
	if not _require(not level.snapshot_error_with_player(bad.level, bad.player).is_empty(), label + " fails complete public native saved-Player/local preflight"): return false
	if not _require(not _shell().attempts.record_snapshot(bad), label + " fails actual canonical model/save validation without writing a generation"): return false
	return _require(_donor_receipt() == before, label + " preserves exact donor/UI/resources/attempt/primary+backup disk and every native identity")


func _direct_native_candidate() -> bool:
	var before: Dictionary = _donor_receipt()
	# Same canonical Shell construction seam used by published Shared34 fixture;
	# no copied recipe, native source binding or save-authority implementation.
	aggregate_candidate = _shell()._prepare("A1-L3", aggregate_saved.equipment_ids, {}, aggregate_saved)
	if not _require(not aggregate_candidate.is_empty(), "real Shell builds actual pristine19 plus exact entitled native prefix before saved-unit validation"): return false
	var candidate_level: CinderLevel = aggregate_candidate.level
	var candidate_hero: CinderPlayer = aggregate_candidate.player
	var map: Dictionary = candidate_level.get("sources")
	var ctor: Dictionary = _native_candidate_probe(candidate_level, candidate_hero)
	if not _require(candidate_level.is_restore_candidate() and candidate_hero.global_position == FullLayout.SPAWN and candidate_level.call("route_state").beat_index == 0 and not candidate_level.finish_restore_candidate() and not candidate_level.request_checkpoint("umbrella-grove") and not candidate_level.request_completion("mushroom-caverns-clear"), "constructor keeps actual fresh Hero/metadata/no gameplay progress and nonplayable entry"): return false
	for id: String in NormalIds:
		var state: Dictionary = map[id].call("pure_presentation_state")
		var native: Dictionary = map[id].call("get_spore_native_bindings")
		var installed: bool = id in CrowdIds + BreathingIds
		if not _require(state.hp == native.configuration.raw_role.max_hp and not state.dead and state.dormant == (not installed) and state.cycle == 0 and state.reservation_id == "" and state.hurt_left_s == 0.0 and state.velocity == Vector3.ZERO and not state.approach_driving and native.player == candidate_hero and native.scheduler == candidate_level.get("scheduler"), "one-shot actual recipient has pristine HP/body/control and exact prefix entitlement: " + id): return false
	if not _require(candidate_level.snapshot_error_with_player(aggregate_saved.level, aggregate_saved.player).is_empty() and _native_candidate_probe(candidate_level, candidate_hero) == ctor and _donor_receipt() == before, "complete mechanical/context/history/resource prevalidation mutates neither pristine candidate nor earlier live donor"): return false
	_watch_quiet(candidate_level, candidate_hero)
	var quiet_before: int = aggregate_quiet_events
	var player_restored: bool = candidate_hero.restore_state(aggregate_saved.player)
	var level_restored: bool = candidate_level.restore_state(aggregate_saved.level) if player_restored else false
	if not _require(player_restored and level_restored, "actual quiet unit restores whole Player first then the real owned aggregate; no gameplay resource seed"): return false
	var optical_error: String = _shell()._candidate_presentation_error(aggregate_candidate, aggregate_saved.shell)
	var native_recaptured: Dictionary = candidate_level.call("_capture_local_state") # actual pure owned producer, not candidate live capture
	if not _require(optical_error.is_empty() and aggregate_quiet_events == quiet_before and Exact.stringify(candidate_hero.snapshot_state()) == Exact.stringify(aggregate_saved.player) and Exact.stringify(native_recaptured) == Exact.stringify(aggregate_saved.level.local) and candidate_level.snapshot_state().is_empty() and candidate_level.is_restore_candidate() and _donor_receipt() == before, "real quiet native19 unit restores exact clocks/HP/fields/stamps/leases silently, passes actual canonical optical gate and remains nonplayable"): return false
	aggregate_receipts.append({"stage": "direct actual quiet native unit", "whole_local_exact_json": Exact.stringify(native_recaptured), "quiet_callback_delta": aggregate_quiet_events - quiet_before, "candidate_live_capture_refused": true})
	var candidate_refs: Array[WeakRef] = [weakref(candidate_level), weakref(candidate_hero)]
	_shell()._dispose(aggregate_candidate); aggregate_candidate = {}
	if not _require(candidate_refs[0].get_ref() == null and candidate_refs[1].get_ref() == null and _donor_receipt() == before, "native constructor disposal frees actual recipients without donor changes"): return false
	aggregate_candidate = _shell()._prepare_snapshot(aggregate_saved)
	if not _require(not aggregate_candidate.is_empty(), "native whole Player/local quiet commit and actual saved-focus/HUD optical gate accept genuine later-room save"): return false
	candidate_level = aggregate_candidate.level; candidate_hero = aggregate_candidate.player
	# End-to-end canonical preparation independently constructs/prevalidates,
	# commits and quiet-gates its OWN recipient; no copied recipe/authority.
	if not _require(candidate_level.is_restore_candidate() and Exact.stringify(candidate_hero.snapshot_state()) == Exact.stringify(aggregate_saved.player) and (aggregate_candidate.camera as Camera3D).global_position == Codec.read_vector3(aggregate_saved.shell.camera_focus) + _shell().CAMERA_OFFSET and _donor_receipt() == before, "canonical whole prepare_snapshot keeps actual saved Player/camera and donor exact"): return false
	var restored_map: Dictionary = candidate_level.get("sources")
	for id: String in NormalIds:
		if not _require(restored_map[id].call("pure_presentation_state").hp == aggregate_saved.level.local.actors[id].hp and restored_map[id].call("pure_presentation_state").dead == aggregate_saved.level.local.actors[id].dead and restored_map[id].call("pure_presentation_state").dormant == aggregate_saved.level.local.actors[id].dormant, "quiet commit applies exact saved source resource/lifecycle without healing: " + id): return false
	_shell()._dispose(aggregate_candidate); aggregate_candidate = {}
	if not _require(_donor_receipt() == before, "assessed candidate disposal preserves donor checkpoint/snapshot/UI/world/actions"): return false
	var wrong_focus: Dictionary = aggregate_saved.duplicate(true)
	wrong_focus.shell.camera_focus[0] += 100.0 # copied optical transport only
	aggregate_candidate = _shell()._prepare_snapshot(wrong_focus)
	# Native failure changes only its diagnostic campaign_error. UI/control,
	# installed bindings/resources/actions, attempts/disk remain in the receipt.
	return _require(aggregate_candidate.is_empty() and not _shell().campaign_error.is_empty() and _shell().get("_validation_candidates").is_empty() and _donor_receipt() == before, "canonical post-quiet gate rejects mechanically valid clipped saved focus and disposes recipient before donor/UI/attempt/disk mutation")


func _native_candidate_probe(candidate_level: CinderLevel, candidate_hero: CinderPlayer) -> Dictionary:
	var actors: Dictionary = {}; var fields: Dictionary = {}; var consumers: Dictionary = {}
	var actor_map: Dictionary = candidate_level.get("sources")
	var field_map: Dictionary = candidate_level.get("_fields")
	var consumer_map: Dictionary = candidate_level.get("_consumers")
	var native_scheduler := candidate_level.get("scheduler") as CinderThreatScheduler
	for id: String in NormalIds:
		var actor: CharacterBody3D = actor_map[id]
		actors[id] = _portable(actor.call("pure_presentation_state"))
	for id: String in field_map: fields[id] = Exact.stringify(field_map[id].snapshot_state())
	for room: String in consumer_map:
		var states: Dictionary = {}
		for id: String in NormalIds: states[id] = _portable(consumer_map[room].source_state(id))
		consumers[room] = states
	return {"hero": Exact.stringify(candidate_hero.snapshot_state()), "actors": actors, "scheduler": Exact.stringify(native_scheduler.snapshot_state(candidate_level.scheduler_bindings())), "fields": fields, "consumers": consumers, "identities": _level_identities(candidate_level, candidate_hero)}


func _watch_quiet(candidate_level: CinderLevel, candidate_hero: CinderPlayer) -> void:
	# Attach AFTER actual constructor and BEFORE the actual direct quiet commit.
	# Birth presentation is not called quiet restore; disposal may notify later.
	candidate_level.checkpoint_requested.connect(func(_id: String, _cp: String, _kind: String) -> void: aggregate_quiet_events += 1)
	candidate_level.completion_requested.connect(func(_id: String, _cp: String) -> void: aggregate_quiet_events += 1)
	candidate_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: aggregate_quiet_events += 1)
	candidate_hero.world_action_executed.connect(func(_record: Dictionary) -> void: aggregate_quiet_events += 1)
	candidate_hero.fired.connect(func(_kind: String) -> void: aggregate_quiet_events += 1)
	candidate_hero.died.connect(func() -> void: aggregate_quiet_events += 1)
	candidate_hero.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: aggregate_quiet_events += 1)
	candidate_hero.equipment_changed.connect(func(_item_id: String) -> void: aggregate_quiet_events += 1)
	var native_scheduler := candidate_level.get("scheduler") as CinderThreatScheduler
	native_scheduler.reservation_invalidated.connect(func(_lease: String, _reason: String) -> void: aggregate_quiet_events += 1)
	for raw: Variant in (candidate_level.get("sources") as Dictionary).values():
		raw.connect("state_changed", func(_state: Dictionary) -> void: aggregate_quiet_events += 1)
		raw.connect("defeated", func(_source: String) -> void: aggregate_quiet_events += 1)
		raw.connect("hit_resolved", func(_target: String, _cycle: int, _result: Dictionary) -> void: aggregate_quiet_events += 1)
		(raw.call("get_cue") as CinderThreatCue).state_changed.connect(func(_state: Dictionary) -> void: aggregate_quiet_events += 1)
	for raw: Variant in (candidate_level.get("_fields") as Dictionary).values():
		raw.connect("state_changed", func(_state: Dictionary) -> void: aggregate_quiet_events += 1)
		raw.connect("activated", func(_domain: Dictionary) -> void: aggregate_quiet_events += 1)
	for raw: Variant in (candidate_level.get("_consumers") as Dictionary).values():
		raw.connect("reaction_started", func(_id: String, _episode: String) -> void: aggregate_quiet_events += 1)
		raw.connect("placement_rejected", func(_id: String, _reason: String) -> void: aggregate_quiet_events += 1)


func _fresh_title_continue(wire: String, donor: Dictionary) -> bool:
	aggregate_fresh = _new_native_shell()
	if aggregate_fresh == null: return false
	for frame: int in range(6): await process_frame
	if not _require(paused and aggregate_fresh.player == null and aggregate_fresh.active_level == null and aggregate_fresh.menu.page_name() == "title" and aggregate_fresh.campaign_error.is_empty(), "real second Shell loads exact disk at Title with NULL installed Player"): return false
	if not _press_menu(aggregate_fresh, "ContinueStoryButton"): return false
	for frame: int in range(8): await process_frame
	if not _require(paused and aggregate_fresh.campaign_error.is_empty() and aggregate_fresh.active_level.scene_file_path == AggregateScene and Exact.stringify(aggregate_fresh.capture_campaign_snapshot()) == wire and _all_bindings_actual(aggregate_fresh) and _identities(aggregate_fresh) != _identities(_shell()) and Exact.stringify(aggregate_fresh.attempts.state().story.checkpoint) == aggregate_earlier_wire and _durable_exact(aggregate_fresh) and _donor_receipt() == donor, "actual fresh disk Continue reconstructs native19/true prefix/leases/fields and exact original resources/view without donor or protected checkpoint mutation"): return false
	aggregate_fresh.free(); aggregate_fresh = null
	return _require(_donor_receipt() == donor, "secondary native recipient cleanup leaves the original paused donor exact")


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > AggregateWallMs:
		_require_unexpected(false, "bounded ten-minute real prefix/native19 candidate fixture")
		_finish.call_deferred()


func _all_bindings_actual(shell: CinderCampaignShell) -> bool:
	if shell.active_level == null or shell.player == null: return _require(false, "actual installed bindings exist")
	var native_level: CinderLevel = shell.active_level
	var actor_map: Dictionary = native_level.get("sources")
	for id: String in NormalIds:
		var actor: CharacterBody3D = actor_map[id]
		var native: Dictionary = actor.call("get_spore_native_bindings")
		if not _require(native.player == shell.player and native.scheduler == native_level.get("scheduler") and actor.get_parent() == native_level and actor.get_world_3d() == shell.player.get_world_3d() and actor.call("body_binding_error") == "" and actor.call("art_binding_error") == "", "actual native retained body/art/world/Player/Scheduler aliases: " + id): return false
	return true


func _level_identities(native_level: CinderLevel, native_hero: CinderPlayer) -> Dictionary:
	var result: Dictionary = {"level": native_level.get_instance_id(), "hero": native_hero.get_instance_id(), "scheduler": (native_level.get("scheduler") as Node).get_instance_id(), "actors": {}, "fields": {}, "consumers": {}}
	for id: String in NormalIds:
		var actor: CharacterBody3D = native_level.get("sources")[id]
		result.actors[id] = [actor.get_instance_id(), actor.get_node("BodyCollision").get_instance_id(), actor.get_node("BodyCollision").shape.get_instance_id(), actor.call("get_art").get_instance_id(), actor.call("get_cue").get_instance_id()]
	for id: String in native_level.get("_fields"): result.fields[id] = native_level.get("_fields")[id].get_instance_id()
	for id: String in native_level.get("_consumers"): result.consumers[id] = native_level.get("_consumers")[id].get_instance_id()
	return result


func _identities(shell: CinderCampaignShell) -> Dictionary:
	var result: Dictionary = _level_identities(shell.active_level, shell.player)
	result["world"] = shell.world.get_instance_id(); result["camera"] = shell.camera.get_instance_id()
	return result


func _ui_receipt(shell: CinderCampaignShell) -> Dictionary:
	var text: Dictionary = {}
	for surface: Node in [shell.menu, shell.hud]:
		for child: Node in surface.find_children("*", "Control", true, false):
			var control := child as Control
			var entry: Array = [control.visible, control.is_visible_in_tree()]
			if control is Label: entry.append((control as Label).text)
			if control is Button: entry.append((control as Button).text); entry.append((control as Button).disabled)
			text[String(control.get_path())] = entry
	return {"page": shell.menu.page_name(), "menu_open": shell.menu.is_open(), "menu_visible": shell.menu.visible, "hud_visible": shell.hud.visible, "controls": text, "hud_safe_rect": shell.hud.combat_safe_rect(), "camera_transform": shell.camera.global_transform, "input": shell.get_input_observation_state(), "level_objective": shell.active_level.objective_text}


func _donor_receipt() -> Dictionary:
	var disk: Dictionary = {}
	for name: String in ["campaign.json", "campaign.json.bak"]:
		var path: String = aggregate_root + name
		disk[name] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null
	return {"ids": _identities(_shell()), "snapshot": Exact.stringify(_shell().capture_campaign_snapshot()), "attempts": Exact.stringify(_shell().attempts.state()), "ui": _ui_receipt(_shell()), "disk": disk, "events": events, "checkpoints": opening_checkpoint_events.duplicate(true), "actions": _portable(hero.get_world_action_records())}


func _durable_exact(shell: CinderCampaignShell) -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(aggregate_root + "campaign.json"))
	if not envelope is Dictionary or envelope.get("format_version") != 2: return false
	var decoded: Dictionary = Exact.parse(String(envelope.get("payload_json", "")))
	return decoded.get("accepted", false) and Exact.stringify(decoded.value) == Exact.stringify(shell.attempts.state())


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if process_frame.is_connected(_aggregate_poll_checkpoint): process_frame.disconnect(_aggregate_poll_checkpoint)
	if process_frame.is_connected(_sample_opening): process_frame.disconnect(_sample_opening)
	if process_frame.is_connected(_sample_crowd): process_frame.disconnect(_sample_crowd)
	if physics_frame.is_connected(_full_phase_observer): physics_frame.disconnect(_full_phase_observer)
	full_pause_target.clear(); aggregate_pending_checkpoint = false
	if is_instance_valid(aggregate_fresh): aggregate_fresh.free(); aggregate_fresh = null
	if is_instance_valid(game):
		if not aggregate_candidate.is_empty(): _shell()._dispose(aggregate_candidate); aggregate_candidate = {}
		var fx: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(fx): fx.clear()
		var until: int = Time.get_ticks_msec() + 500
		while Time.get_ticks_msec() < until: await process_frame
		game.free()
	paused = false; await process_frame
	_require(FileAccess.get_file_as_string(AggregateRegistry.DATA_PATH) == aggregate_registry_text or aggregate_registry_text.is_empty(), "fixture never mutates canonical registry")
	var evidence: String = "res://.cinder/l3-full-aggregate-fixture-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(evidence, FileAccess.WRITE)
	if file == null:
		checks += 1; failures += 1; push_error("native aggregate fixture report unavailable")
	else:
		file.store_string(JSON.stringify({"scope": "TEST predecessors/registry only; genuine neutral Standard umbrella ordinary clear + breathing warning; native full19 aggregate candidate/TitleContinue/earlierRetry attempt; no all19 clear/fulllevel/portrait/profile-kit/sporedepletion/human/FPS acceptance", "checks": checks, "failures": failures, "real_swipes": swipes, "real_ordinary_primaries": primaries, "receipts": aggregate_receipts, "native_phase_observations": _portable(phase_observations), "diagnostics": full_diagnostics, "fixture_mode": "selected native aggregate/candidate prefix only"}, "\t")); file.close()
	var directory := DirAccess.open(aggregate_root)
	if directory != null:
		for name: String in directory.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(aggregate_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(aggregate_root))
	Engine.max_fps = aggregate_old_fps; AudioServer.set_bus_layout(aggregate_old_audio)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 NATIVE FULL-AGGREGATE PREFIX/CANDIDATE ATTEMPT: %d checks/%d failures; %d recognizer swipes/%d ordinary primaries; TEST PREDECESSORS ONLY / NO FULL19 CLEAR / NO LEVEL ACCEPTANCE" % [checks, failures, swipes, primaries])
	quit(1 if failures else 0)
