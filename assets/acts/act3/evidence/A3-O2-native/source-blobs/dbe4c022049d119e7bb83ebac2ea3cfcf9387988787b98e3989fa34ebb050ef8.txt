extends "res://tests/acts/act3/pillars_before_time_optional_shell.gd"
## Final O2 public Optional flow. Reuse accepted generic Shell helpers and the
## focused fixture's native Root response driver in this actual production Shell.
## TEST ONLY O2 accepted metadata + prefix12; actual accepted A3-L2 Story packet.
## No Hero/resource/clock/history/death/lease/progress writes or court CP seed.
## Default: actual CP1, next Root warning/Save/disk Resume/Retry/early Leave.
## Explicit --completion-return: actual CP2 Retry/completion/contact/Replay.
## Direct public native actions do not claim gestures, portrait or balance.

const O2_PATH: String = "res://scenes/acts/act3/a3_o2_quiet_root_circuit.tscn"
const O2_ROOT: String = "o2-first-root"
const O2_HELD_ROOT: String = "o2-second-root"
const O2_OWNER: String = "o2-second-root/attack"
const QRC = preload("res://scripts/acts/act3/quiet_root_circuit.gd")
const Focused = preload("res://tests/acts/act3/quiet_root_circuit_focused.gd")
const NativeObservers = preload("res://tests/acts/act3/pillars_before_time_focused.gd")
const O2Geometry = preload("res://scripts/combat/threat_geometry.gd")
const O2_ADOPTED: String = "aea69b3ea47b435894c0340b3436b2da8f523c89"
const O2_PINS: Array[String] = [
	"res://tests/acts/act3/quiet_root_circuit_optional_shell.gd",
	"res://tests/acts/act3/pillars_before_time_optional_shell.gd",
	"res://tests/acts/act3/quiet_root_circuit_focused.gd", "res://tests/acts/act3/pillars_before_time_focused.gd",
	"res://scripts/acts/act3/quiet_root_circuit.gd", "res://scenes/acts/act3/a3_o2_quiet_root_circuit.tscn",
	"res://data/campaign/act3/a3_o2_encounters.json", "res://scripts/acts/act3/living_forest.gd",
	"res://scripts/acts/act3/living_forest_scenery.gd", "res://scripts/acts/act3/root_latcher.gd",
	"res://scripts/acts/act3/root_latcher_art.gd", "res://scripts/acts/act3/garden_root_latcher.gd",
	"res://scripts/acts/act3/sunbound_stalker.gd", "res://scripts/combat/lane_mechanism.gd",
	"res://scripts/combat/body_sweep.gd", "res://scripts/combat/threat_geometry.gd",
	"res://scripts/combat/threat_scheduler.gd", "res://scripts/campaign/shell.gd", "res://scripts/campaign/level.gd",
	"res://scripts/campaign/registry.gd", "res://scripts/campaign/save_store.gd", "res://scripts/campaign/exact_json.gd",
	"res://scripts/campaign/snapshot_codec.gd", "res://scripts/player.gd", "res://scripts/game.gd",
	"res://scripts/hud.gd", "res://scripts/ui/campaign_menu.gd", "res://scripts/equipment.gd",
	"res://data/design/player_equipment.json",
]

var _o2_barrier: NativeObservers.PostActorBarrier
var _o2_hero: CinderPlayer
var _o2_level: CinderLevel
var _o2_scheduler: CinderThreatScheduler
var _o2_selected: String = O2_ROOT
var _o2_kit: Dictionary = {}
var _o2_hp: float = 0.0
var _o2_deaths: int = 0
var _o2_fired: Array[String] = []
var _o2_ticks: int = 0

func _initialize() -> void:
	isolated = "user://test-a3-o2-optional-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	_run.call_deferred()

func _run() -> void:
	create_timer(180.0, true, false, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "bounded final O2 public-flow watchdog")
			_finish())
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	completion_return = arguments == PackedStringArray(["--completion-return"])
	if not _expect(DisplayServer.get_name() == "headless" and (arguments.is_empty() or completion_return), "explicit headless held transport or --completion-return; no portrait credit"):
		await _finish(); return
	var parsed: Variant = JSON.parse_string(canonical_bytes)
	if not _expect(parsed is Dictionary, "canonical registry loads read-only for isolated O2 metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for row: Dictionary in raw.levels:
		if row.id == "A3-O2":
			row.scene_path = O2_PATH
			row.readiness = "accepted"
			row.accepted_commit = "b".repeat(40) # TEST ONLY provenance, never integration acceptance.
			row.api_revision = Registry.API_REVISION
	var registry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A3-O2").is_empty() and registry.entry("A3-O2").parent_level_id == "A3-L2", "isolated O2 metadata keeps canonical parent/reward/route links", registry.last_error):
		await _finish(); return
	node_added.connect(_watch_node)
	print("O2 TEST ONLY prefix12/readiness; unchanged real A3-L2 older Story unit. Actual native Root response/primary earns all tested court boundaries inside this production Optional Shell; no actor/progress/lease seed.")
	if not await _seed_story(registry) or not await _new_shell(expected_session): await _finish(); return
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", protected): await _finish(); return
	if not _installed(protected) or not _quiet_selected(): await _finish(); return
	var old_story_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_story_refs)
	var old_story_ids: Dictionary = _core_ids()
	production.menu.optional_requested.emit("A3-O2")
	if not await _wait_installed("A3-O2", "resume", {}, old_story_ids): await _finish(); return
	var entrance: Dictionary = production.capture_campaign_snapshot()
	checkpoint = production.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _installed(entrance) or not await _released(old_story_refs, "Optional entry retires complete old Story world"): await _finish(); return
	var initial: Dictionary = production.active_level.call("state")
	if not _expect(production.attempts.active_kind() == "optional" and _same(checkpoint, entrance) and _same(production.attempts.state().story, expected_session.story) and initial.clears.is_empty() and initial.deaths.is_empty() and not initial.completed and entrance.level.progress.checkpoint_id.is_empty() and production.player.get_world_action_records().is_empty(), "actual O2 entry protects whole Story and its own pristine no-court-checkpoint entrance"):
		await _finish(); return
	if not _expect(not production.active_level.request_contact_exit("quiet-root-return-threshold", production.player) and _same(production.capture_campaign_snapshot(), entrance), "uncleared O2 exit refuses atomically before any genuine Root death"):
		await _finish(); return
	if completion_return:
		scope_complete = await _o2_completion_return()
		await _finish(); return
	if not _o2_bind_live() or not await _resume_after_layout(): await _finish(); return
	if not await _o2_clear_root(O2_ROOT) or not await _o2_checkpoint(1): await _finish(); return
	if (await _o2_warning(O2_HELD_ROOT)).is_empty(): await _finish(); return
	production.request_pause()
	if not await _wait_pause(): await _finish(); return
	held = production.capture_campaign_snapshot()
	var receipt: Dictionary = _held_receipt()
	if not _expect(not receipt.is_empty() and _same(production.attempts.active_snapshot(), held) and _same(production.attempts.state().side_attempt.checkpoint, checkpoint) and not _same(held, checkpoint) and held.level.progress.checkpoint_id == QRC.CHECKPOINT_IDS[0] and held.level.local.route.active_court == 1 and held.level.local.route.deaths.size() == 1, "public Pause saves actual second Root warning separately from real first-court CP1"):
		await _finish(); return
	if not _installed(held) or not _disk(production.attempts.state()) or not _archive_held(entrance, receipt): await _finish(); return
	if not _expect(not production.active_level.request_checkpoint(QRC.CHECKPOINT_IDS[0]) and _same(production.capture_campaign_snapshot(), held), "duplicate actual CP1 request refuses without changing held aggregate"): await _finish(); return
	var saved: Dictionary = production.attempts.state()
	var donor_ids: Dictionary = _native_ids()
	if not await _dispose_shell() or not await _new_shell(saved): await _finish(); return
	production.menu.resume_requested.emit() # Public Title Resume Side; Continue Story would abandon it.
	if not await _wait_installed("A3-O2", "resume", held): await _finish(); return
	if not _installed(held) or not _distinct(donor_ids) or not _quiet_selected(): await _finish(); return
	if not _expect(_same(_held_receipt(), receipt) and _same(production.attempts.state(), saved), "fresh disk Side Resume retains complete original Root/Mechanism warning lease/cycle/clock/session"):
		await _finish(); return
	var old_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_refs)
	var old_ids: Dictionary = _native_ids()
	receiver_events.clear()
	production.menu.retry_requested.emit()
	if not await _wait_installed("A3-O2", "resume", checkpoint, old_ids): await _finish(); return
	if not _installed(checkpoint) or not _distinct(old_ids) or not _quiet_selected() or not await _released(old_refs, "CP1 Retry frees original whole five-source/Mechanism/field/floor world"):
		await _finish(); return
	if not _expect(_same(production.attempts.active_snapshot(), checkpoint) and _same(production.attempts.state().side_attempt.checkpoint, checkpoint) and _same(production.attempts.state().story, expected_session.story), "public Retry restores actual whole first-court CP1 without Story refresh"):
		await _finish(); return
	if not _disk(production.attempts.state()) or not await _gui_resume(checkpoint): await _finish(); return
	old_refs.clear()
	_collect_refs(_world_container(), old_refs)
	var before_leave: Dictionary = _core_ids()
	production.menu.leave_side_requested.emit()
	if not await _wait_installed(STORY_ID, "journey", protected, before_leave): await _finish(); return
	if not _installed(protected) or not await _released(old_refs, "early Leave Side retires complete optional Root world"): await _finish(); return
	var returned: Dictionary = production.attempts.state()
	if not _expect(returned.side_attempt == null and returned.completed_main == expected_session.completed_main and returned.completed_optional.is_empty() and returned.reward_ids.is_empty() and _same(returned.story, expected_session.story), "early Leave returns Journey with complete older Story/checkpoint and no optional reward or route advance"):
		await _finish(); return
	if not _disk(returned): await _finish(); return
	scope_complete = true
	await _finish()

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	# Parent constructs/captures the actual accepted L2 opening and normally
	# retires it. Only detached TEST predecessor metadata changes afterward.
	if not await super._seed_story(registry): return false
	var packet_before: String = Exact.stringify(protected)
	expected_session.completed_main = registry.main_route().slice(0, 12)
	var detached = Attempts.new(registry)
	var error: String = detached.state_error(expected_session)
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = detached.saved_payload_error
	if not _expect(error.is_empty() and expected_session.completed_main[-1] == "A3-L2" and packet_before == Exact.stringify(protected) and _same(expected_session.story.snapshot, protected) and _same(expected_session.story.checkpoint, protected) and writer.write_payload(expected_session), "validated detached TEST prefix12 preserves genuine older A3-L2 Story/actor/local/input/camera packet byte-exact", error + "; " + writer.last_error): return false
	return _disk(expected_session)

func _o2_bind_live() -> bool:
	_o2_hero = production.player
	_o2_level = production.active_level
	_o2_scheduler = _o2_level.get("threat_scheduler") as CinderThreatScheduler
	_o2_kit = _o2_hero.equipment.snapshot()
	_o2_hp = _o2_hero.hp
	_o2_deaths = (_o2_level.call("state") as Dictionary).deaths.size()
	_o2_fired.clear()
	var sources: Dictionary = _o2_level.get("sources")
	var bindings: Dictionary = _o2_level.call("scheduler_bindings")
	if not _expect(paused and QRC.LOCAL_VERSION == 2 and sources.size() == 5 and bindings.owners.size() == 5 and bindings.actors.hero == _o2_hero and _o2_hp == _o2_hero.max_hp, "real final Optional recipient binds all five native actors and unchanged full-HP kit"): return false
	for id: String in QRC.SOURCE_IDS:
		var source: Node3D = sources[id]
		var owner: Node3D = source.call("get_mechanism") as Node3D if QRC.SOURCE_KINDS[id] == "root" else source
		var owner_id: String = id + "/attack" if QRC.SOURCE_KINDS[id] == "root" else id
		if not _expect(source.get_world_3d() == _o2_hero.get_world_3d() and bindings.owners.get(owner_id) == owner and (QRC.SOURCE_KINDS[id] != "root" or source.global_position == QRC.SOURCE_POSITIONS[id]), "real typed native source/Mechanism owner in Optional World: " + id): return false
		if QRC.SOURCE_KINDS[id] == "root": source.connect("died", _o2_count_death)
	_o2_hero.fired.connect(_o2_record_fired)
	if not is_instance_valid(_o2_barrier):
		_o2_barrier = NativeObservers.PostActorBarrier.new()
		_o2_barrier.name = "OptionalQuietRootNativeObserver"
		root.add_child(_o2_barrier)
	return true

func _o2_count_death(_position: Vector3) -> void:
	_o2_deaths += 1

func _o2_record_fired(kind: String) -> void:
	_o2_fired.append(kind)

func _o2_actions() -> Array:
	return _o2_hero.get_world_action_records()

func _o2_fired_kinds() -> Array:
	return _o2_fired

func _o2_death_count() -> int:
	return _o2_deaths

func _o2_driver(id: String) -> RefCounted:
	_o2_selected = id
	var driver = Focused.NativeRootResponse.new()
	driver.configure(_o2_hero, _o2_level, _o2_scheduler, (_o2_level.get("sources") as Dictionary)[id] as CinderAct3RootLatcher, id, _o2_kit, _o2_actions, _o2_fired_kinds, _o2_death_count, _o2_tick, _o2_presentation, _expect)
	return driver

func _o2_tick() -> bool:
	# CP/complete are genuine asynchronous Shell transactions. Observe their
	# automatic pause/drain/resume before asking for the next physical tick.
	for _frame: int in range(FRAME_LIMIT):
		if finished or not _valid_shell(): return false
		if paused:
			await process_frame
			continue
		_o2_barrier.waiting = true
		_o2_barrier.expiration = Engine.get_process_frames() + FRAME_LIMIT
		var boundary: String = await _o2_barrier.observed
		if finished: return false
		if boundary == "paused_notification": continue
		_o2_ticks += 1
		var state: Dictionary = _o2_level.call("state")
		return _expect(boundary == "post_actor_physics" and not paused and _o2_ticks <= 6000 and production.active_level == _o2_level and production.player == _o2_hero and not _o2_hero.dead and _o2_hero.hp == _o2_hp and _o2_hero.equipment.snapshot() == _o2_kit and state.configuration_error.is_empty() and (_o2_level.get("sources") as Dictionary)[_o2_selected].global_position == QRC.SOURCE_POSITIONS[_o2_selected], "bounded real post-actor Optional tick preserves native full HP/kit/fixed Root", str({"boundary": boundary, "clock_s": _o2_scheduler.get_clock(), "ticks": _o2_ticks, "hero": _o2_hero.global_position, "hero_hp": _o2_hero.hp, "starting_hp": _o2_hp, "hero_dead": _o2_hero.dead, "actual_kit": _o2_hero.equipment.snapshot(), "expected_kit": _o2_kit, "actual_selected_position": (_o2_level.get("sources") as Dictionary)[_o2_selected].global_position, "expected_selected_position": QRC.SOURCE_POSITIONS[_o2_selected], "state": state}))
	return _expect(false, "bounded automatic Shell court transaction resumes actual native ticking")

func _o2_presentation() -> bool:
	for _frame: int in range(FRAME_LIMIT):
		if finished or not _valid_shell(): return false
		if paused:
			await process_frame
			continue
		_o2_barrier.presentation_waiting = true
		_o2_barrier.presentation_expiration = Engine.get_process_frames() + FRAME_LIMIT
		var boundary: String = await _o2_barrier.presentation_observed
		if finished: return false
		if boundary == "unexpected_paused_process": continue
		return _expect(boundary == "post_presentation_process" and not paused and production.player == _o2_hero and _o2_hero.hp == _o2_hp and not _o2_hero.dead and _o2_hero.equipment.snapshot() == _o2_kit, "actual Shell HUD/camera process follows the native Root response")
	return _expect(false, "bounded automatic Shell transaction reaches current native presentation")

func _o2_warning(id: String) -> Dictionary:
	var driver: RefCounted = _o2_driver(id)
	var source: CinderAct3RootLatcher = (_o2_level.get("sources") as Dictionary)[id] as CinderAct3RootLatcher
	# Let the newly enabled court issue its actual warning before any approach.
	if not await _o2_tick(): return {}
	# Fresh Shell entry starts above the floor; let ordinary gravity settle it
	# exactly as the focused Main fixture does before asking for a body sweep.
	for _settle: int in range(8):
		if _o2_hero.is_on_floor(): break
		if not await _o2_tick(): return {}
	if not _expect(_o2_hero.is_on_floor(), "native Optional Hero settles on continuous floor before approach"): return {}
	var approaches: int = 0
	for _index: int in range(480):
		if finished or not _valid_shell(): return {}
		if paused:
			if not await _o2_tick(): return {}
		var state: Dictionary = source.state()
		var proof: Dictionary = state.proof
		var usable: bool = state.phase == "warning" and proof.get("path") is Array and not proof.path.is_empty() and proof.path[0].from.distance_to(_o2_hero.global_position) <= 0.02
		if usable:
			for segment: Dictionary in proof.path:
				if segment.kind == "escape_dash":
					usable = _o2_scheduler.get_clock() <= float(segment.start_s) + 0.00001
					break
		if usable:
			var record: Dictionary = _o2_scheduler.reservation_state(String(state.mechanism.reservation_id))
			var path: Array[Dictionary] = []
			for segment: Dictionary in proof.path: path.append(segment)
			if not _expect(not record.is_empty() and record.armed and record.source_instance_id == source.get_mechanism().get_instance_id() and record.geometry.kind == "crescent" and record.geometry.origin == source.global_position and record.geometry == state.geometry and proof.get("accepted", false) and not proof.get("uses_blast", true) and not proof.get("uses_invulnerability", true) and not O2Geometry.timed_path_hits(record.geometry, path, float(record.active_from_s), float(record.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN), "actual Optional Root warning retains its current-point native ordinary escape/return witness: " + id, str(state)): return {}
			return {"proof": proof.duplicate(true), "record": record.duplicate(true)}
		var toward: Vector3 = source.global_position - _o2_hero.global_position
		toward.y = 0
		if state.mechanism.status != "running" and toward.length() > 2.8 and approaches < 3:
			approaches += 1
			if not await driver.call("approach"): return {}
		elif not await _o2_tick(): return {}
	_expect(false, "bounded current-point Root warning in actual Optional Shell", str({"id": id, "hero": _o2_hero.global_position, "source": source.state()}))
	return {}

func _o2_clear_root(id: String) -> bool:
	var warning: Dictionary = await _o2_warning(id)
	if warning.is_empty(): return false
	var driver: RefCounted = _o2_driver(id)
	return bool(await driver.call("follow", warning.proof, warning.record))

func _o2_checkpoint(count: int) -> bool:
	for _frame: int in range(FRAME_LIMIT):
		if not _valid_shell() or production.player.dead: return false
		var side: Variant = production.attempts.state().side_attempt
		if side != null and side.checkpoint.level.progress.checkpoint_id == QRC.CHECKPOINT_IDS[count - 1]:
			checkpoint = side.checkpoint.duplicate(true)
			var ids: Dictionary = {}
			for index: int in range(count): ids[QRC.CHECKPOINT_IDS[index]] = "encounter"
			return _expect(_same(checkpoint.level.progress.checkpoint_ids, ids) and checkpoint.level.local_snapshot_version == QRC.LOCAL_VERSION and checkpoint.level.local.api_revision == QRC.ROUTE_API and checkpoint.level.local.sources.size() == 5 and checkpoint.level.local.route.active_court == count and checkpoint.level.local.route.clears.size() == count and checkpoint.level.local.route.deaths.size() == count and not checkpoint.level.progress.completed and _same(production.attempts.state().story, expected_session.story), "real native court boundary is durable complete Optional checkpoint " + str(count))
		await process_frame
	return _expect(false, "bounded genuine Optional checkpoint " + str(count))

func _o2_completion_return() -> bool:
	var stats: PackedByteArray = var_to_bytes(production.player.stats)
	var unlocks: Array = production.attempts.state().unlocked_equipment.duplicate()
	var gear: Dictionary = production.player.equipment.snapshot()
	if not _o2_bind_live() or not await _resume_after_layout(): return false
	if not await _o2_clear_root(O2_ROOT) or not await _o2_checkpoint(1): return false
	if not await _o2_clear_root(O2_HELD_ROOT) or not await _o2_checkpoint(2): return false
	var latest: Dictionary = checkpoint.duplicate(true)
	production.request_pause()
	if not await _wait_pause(): return false
	if not _expect(not _same(production.capture_campaign_snapshot(), latest) and _same(production.attempts.state().side_attempt.checkpoint, latest), "genuine later active unit differs from real CP2 while Pause retains latest Retry"): return false
	if not _disk(production.attempts.state()): return false
	var retired: Array[WeakRef] = []
	_collect_refs(_world_container(), retired)
	var previous: Dictionary = _native_ids()
	receiver_events.clear()
	production.menu.retry_requested.emit()
	if not await _wait_installed("A3-O2", "resume", latest, previous): return false
	if not _installed(latest) or not _distinct(previous) or not _quiet_selected() or not await _released(retired, "latest CP2 Retry retires all five original native sources/Mechanisms/floor/World"): return false
	if not _expect(_same(production.attempts.active_snapshot(), latest) and _same(production.attempts.state().side_attempt.checkpoint, latest) and _same(production.attempts.state().story, expected_session.story), "public Retry restores exact genuine CP2 whole unit and older protected Story"): return false
	if not _disk(production.attempts.state()) or not await _gui_resume(latest): return false
	if not _o2_bind_live() or not await _resume_after_layout(): return false
	if not await _o2_clear_root("o2-final-west-root") or not await _o2_clear_root("o2-final-east-root"): return false
	if not await _o2_completed(latest, stats, unlocks) or not await _o2_contact_return("optional", latest): return false
	var completed_session: Dictionary = production.attempts.state()
	var story_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), story_refs)
	var story_ids: Dictionary = _core_ids()
	production.menu.replay_requested.emit("A3-O2", gear.duplicate(true))
	if not await _wait_installed("A3-O2", "resume", {}, story_ids): return false
	var replay_entrance: Dictionary = production.capture_campaign_snapshot()
	if not _installed(replay_entrance) or not await _released(story_refs, "public Replay retires protected Story recipient before fresh Optional unit"): return false
	if not _expect(production.attempts.active_kind() == "replay" and replay_entrance.level.local.route.deaths.is_empty() and not replay_entrance.level.progress.completed and production.player.equipment.snapshot() == gear and _same(production.attempts.state().story, expected_session.story) and _same(production.attempts.state().completed_optional, completed_session.completed_optional) and _same(production.attempts.state().reward_ids, completed_session.reward_ids), "public Replay starts genuine fresh O2 while retaining original one-time stamp and whole Story"): return false
	if not _o2_bind_live() or not await _resume_after_layout(): return false
	if not await _o2_clear_root(O2_ROOT) or not await _o2_checkpoint(1): return false
	if not await _o2_clear_root(O2_HELD_ROOT) or not await _o2_checkpoint(2): return false
	var replay_checkpoint: Dictionary = checkpoint.duplicate(true)
	if not await _o2_clear_root("o2-final-west-root") or not await _o2_clear_root("o2-final-east-root"): return false
	if not await _o2_completed(replay_checkpoint, stats, unlocks) or not await _o2_contact_return("replay", replay_checkpoint): return false
	return _expect(_same(production.attempts.state().completed_main, expected_session.completed_main) and _same(production.attempts.state().completed_optional, completed_session.completed_optional) and _same(production.attempts.state().reward_ids, completed_session.reward_ids) and _same(production.attempts.state().unlocked_equipment, unlocks) and _same(production.attempts.state().story, expected_session.story), "real Replay completion/contact return deduplicates stamp and preserves Story/main/static availability") and _disk(production.attempts.state())

func _o2_completed(latest: Dictionary, stats: PackedByteArray, unlocks: Array) -> bool:
	production.request_pause()
	if not await _wait_pause(): return false
	var snapshot: Dictionary = production.capture_campaign_snapshot()
	var state: Dictionary = production.attempts.state()
	var owner: String = str(production.active_level.get_instance_id())
	var stamp: String = production.registry.entry("A3-O2").reward_id
	var stalker: Node = (production.active_level.get("sources") as Dictionary)["o2-final-stalker"]
	if not _expect(snapshot.level.progress.completed and snapshot.level.progress.completion_id == QRC.COMPLETION_ID and snapshot.level.progress.contact_exit_id.is_empty() and snapshot.level.local.route.active_court == 3 and snapshot.level.local.route.clears.size() == 3 and snapshot.level.local.route.deaths.size() == 4 and not stalker.get("dead") and float(stalker.get("hp")) > 0.0 and _same(state.side_attempt.checkpoint, latest) and state.completed_optional == ["A3-O2"] and state.reward_ids == [stamp] and state.completed_main == expected_session.completed_main and _same(state.unlocked_equipment, unlocks) and var_to_bytes(production.player.stats) == stats and _same(state.story, expected_session.story) and _owner_events(owner, "completion_requested") == 1, "third real court clear stamps once without CP3/static stat growth; final Stalker lives and protected Story remains"): return false
	var before: String = Exact.stringify(snapshot)
	var events: PackedByteArray = var_to_bytes(receiver_events)
	if not _expect(not production.active_level.request_completion(QRC.COMPLETION_ID) and before == Exact.stringify(production.capture_campaign_snapshot()) and _same(production.attempts.state(), state) and events == var_to_bytes(receiver_events), "duplicate actual completion refuses atomically without another stamp/event"): return false
	return _installed(snapshot) and _disk(state)

func _o2_observe_contact(id: String, exit_id: String, owner: WeakRef) -> void:
	var level: Node = owner.get_ref() as Node
	if not _expect(level != null and id == "A3-O2" and exit_id == QRC.EXIT_ID, "real native contact event carries canonical O2 exit"): return
	var state: Dictionary = level.call("state")
	contact_receipts[str(level.get_instance_id())] = {"contact": state.contact.duplicate(true), "clears": state.clears.duplicate(true), "deaths": state.deaths.duplicate(true)}

func _o2_contact_return(kind: String, latest: Dictionary) -> bool:
	var level: CinderLevel = production.active_level
	var owner: String = str(level.get_instance_id())
	level.contact_exit_requested.connect(_o2_observe_contact.bind(weakref(level)))
	var refs: Array[WeakRef] = []
	_collect_refs(_world_container(), refs)
	var previous: Dictionary = _core_ids()
	if not await _resume_after_layout() or not await _o2_exit_approach(): return false
	if not await _wait_installed(STORY_ID, "journey", protected, previous): return false
	if not _installed(protected) or not await _released(refs, "real Optional/Replay contact retires entire five-source World"): return false
	if not _expect(contact_receipts.has(owner) and _owner_events(owner, "contact_exit_requested") == 1 and production.attempts.active_kind() == "story" and production.attempts.state().side_attempt == null and _same(production.attempts.state().story, expected_session.story), "one later grounded native contact returns whole protected Story/Journey"): return false
	var reader = Store.new(isolated + "campaign.json.bak")
	var prior: Dictionary = reader.read_payload()
	var side: Variant = prior.get("side_attempt")
	var observed: Dictionary = contact_receipts[owner]
	if not _expect(reader.last_error.is_empty() and not reader.loaded_backup and side != null and side.kind == kind and side.level_id == "A3-O2" and side.snapshot.level.progress.contact_exit_id == QRC.EXIT_ID and side.snapshot.level.progress.completed and _same(side.snapshot.level.local.route.contact, observed.contact) and _same(side.snapshot.level.local.route.clears, observed.clears) and _same(side.snapshot.level.local.route.deaths, observed.deaths) and _same(side.checkpoint, latest) and _same(prior.story, expected_session.story), "original independent format2 backup retains latched genuine contact/four Root deaths/CP2/protected Story", reader.last_error): return false
	return _disk(production.attempts.state())

func _o2_exit_approach() -> bool:
	# A small native geometry plan reaches the authored contact with unchanged
	# full-distance dashes. No Hero placement or controller tuning is performed.
	for _leg: int in range(6):
		if not _valid_shell(): return false
		if production.active_level.level_id == STORY_ID: return true
		var actor: CinderPlayer = production.player
		var start: Vector3 = actor.global_position
		var target: Vector3 = Vector3(QRC.EXIT_POSITION.x, start.y, QRC.EXIT_POSITION.z)
		var delta: Vector3 = target - start
		var distance: float = float(actor.get_threat_response_state().stats.dash_distance)
		if QRC.EXIT_RECT.has_point(Vector2(start.x, start.z)):
			for _frame: int in range(FRAME_LIMIT):
				await process_frame
				if not _valid_shell(): return false
				if production.active_level.level_id == STORY_ID: return true
			return _expect(false, "bounded real grounded authored exit contact")
		var direction: Vector3 = delta.normalized()
		if delta.length() < 2.0 * distance and absf(delta.length() - distance) > 0.01:
			var middle: Vector3 = (start + target) * 0.5
			var sideways: Vector3 = Vector3.UP.cross(direction)
			var height: float = sqrt(maxf(0.0, distance * distance - delta.length_squared() * 0.25))
			var found: bool = false
			for sign_value: float in [1.0, -1.0]:
				var via: Vector3 = middle + sideways * height * sign_value
				var pose: Transform3D = actor.global_transform
				var floors: Array = (production.active_level.call("scheduler_bindings") as Dictionary).floors.values()
				var first: Dictionary = BodySweep.sweep(actor, pose, via - start, floors)
				pose.origin = via
				var second: Dictionary = BodySweep.sweep(actor, pose, target - via, floors)
				if first.has("error") or second.has("error") or first.get("collided", true) or second.get("collided", true): continue
				if (first.end as Vector3).distance_to(via) > 0.005 or (second.end as Vector3).distance_to(target) > 0.005: continue
				direction = (via - start).normalized()
				found = true
				break
			if not _expect(found, "actual body/floor supports a two-dash native approach to the north exit", str({"start": start, "target": target})): return false
		if not await _o2_contact_dash(direction): return false
	return _expect(false, "bounded six-dash genuine exit approach")

func _o2_contact_dash(direction: Vector3) -> bool:
	for _frame: int in range(LIVE_FRAME_LIMIT):
		await process_frame
		if not _valid_shell(): return false
		if production.active_level.level_id == STORY_ID: return true
		if production.player.dead: return _expect(false, "real contact approach retains living Hero")
		if paused: continue
		var actor: CinderPlayer = production.player
		var response: Dictionary = actor.get_threat_response_state()
		if not response.get("stable", false) or float(response.dash_cooldown_left_s) != 0.0 or actor.action_in_progress(): continue
		var start: Vector3 = actor.global_position
		var motion: Vector3 = direction * float(actor.get_threat_response_state().stats.dash_distance)
		var swept: Dictionary = BodySweep.sweep(actor, actor.global_transform, motion, (production.active_level.call("scheduler_bindings") as Dictionary).floors.values())
		if not _expect(not swept.has("error") and not swept.get("collided", true) and (swept.end as Vector3).distance_to(start + motion) <= 0.005, "actual native exit dash retains full supported body sweep", str(swept)): return false
		var sequence: int = _sequence()
		if not _expect(actor.request_dash(direction), "public Hero accepts actual exit approach dash"): return false
		for _tick: int in range(FRAME_LIMIT):
			await process_frame
			if not _valid_shell(): return false
			if production.active_level.level_id == STORY_ID:
				return _expect(not contact_receipts.is_empty(), "native contact may replace in-flight exit dash; no completed-dash credit")
			if production.player != actor or actor.dead: return _expect(false, "original living actual Hero remains until authored contact")
			var records: Array[Dictionary] = actor.get_world_action_records(sequence)
			if records.size() == 1 and not actor.action_in_progress():
				return _expect(records[0].kind == "dash" and not records[0].blocked and not records[0].collision_shortened and records[0].world_origin == start and records[0].landing == actor.global_position and (records[0].landing as Vector3).distance_to(start + motion) <= 0.005 and not CinderPlayer.encode_world_action_record(records[0], actor.get_world_action_clock()).is_empty(), "genuine completed exit approach dash retains native full-distance record")
		return _expect(false, "bounded real native exit dash/contact transaction")
	return _expect(false, "bounded actual exit dash readiness")


func _held_receipt() -> Dictionary:
	var level: CinderLevel = production.active_level
	var root_source: Node = level.get("sources")[O2_HELD_ROOT]
	var mechanism: Node3D = root_source.call("get_mechanism") as Node3D
	var state: Dictionary = root_source.call("state")
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	var control: Dictionary = scheduler.source_control_state(mechanism)
	var bindings: Dictionary = level.call("scheduler_bindings")
	var native: Dictionary = state.mechanism
	if state.phase != "warning" or native.status != "running" or native.phase != "warning" or String(native.reservation_id).is_empty() or control.get("reservations", []).size() != 1: return {}
	var lease: Dictionary = control.reservations[0]
	if state.source_id != O2_OWNER or bindings.owners.get(O2_OWNER) != mechanism or control.source_instance_id != mechanism.get_instance_id() or native.mechanism_id != O2_OWNER or lease.id != native.reservation_id or lease.state != "warning" or control.clock_s != scheduler.get_clock() or state.clock_s != scheduler.get_clock(): return {}
	return {"source_id": O2_HELD_ROOT, "mechanism_id": O2_OWNER, "phase": "warning", "reservation_id": native.reservation_id, "cycle": native.cycle, "clock_s": scheduler.get_clock(), "hp": state.hp, "dead": state.dead}

func _native_ids() -> Dictionary:
	var result: Dictionary = _core_ids()
	var level: CinderLevel = production.active_level
	result.scheduler = (level.get("threat_scheduler") as Node).get_instance_id()
	var sources: Dictionary = level.get("sources")
	for id: String in sources: result["source/" + id] = (sources[id] as Node).get_instance_id()
	result.source = (sources[O2_HELD_ROOT] as Node).get_instance_id()
	var bindings: Dictionary = level.call("scheduler_bindings")
	for id: String in bindings.owners: result["owner/" + id] = (bindings.owners[id] as Node).get_instance_id()
	for id: String in bindings.floors:
		var collision: CollisionShape3D = bindings.floors[id].collision
		result["collision/" + id] = collision.get_instance_id()
		result["floor/" + id] = collision.get_parent().get_instance_id()
	result.exit_cue = (level.get("exit_cue") as Node).get_instance_id()
	return result

func _archive_held(entrance: Dictionary, receipt: Dictionary) -> bool:
	if not _expect(paused and receipt.get("phase") == "warning" and _same(production.capture_campaign_snapshot(), held) and _same(production.attempts.active_snapshot(), held), "archive only genuine paused Root warning and complete native active session"): return false
	archive_path = "res://captures/act3/quiet-root-circuit/optional-held-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(archive_path)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(archive_path)) == OK, "new O2 archive preserves all prior originals"): return false
	var values: Dictionary = {"session.native.json": production.attempts.state(), "held.native.json": held, "entrance.native.json": entrance, "checkpoint.native.json": checkpoint, "story.native.json": protected, "start-session.native.json": expected_session, "registry.native.json": raw}
	var files: Dictionary = {}
	for filename: String in values:
		var wire: String = Exact.stringify(values[filename])
		var file: FileAccess = FileAccess.open(archive_path.path_join(filename), FileAccess.WRITE)
		if not _expect(not wire.is_empty() and file != null, "complete finite native O2 archive file opens: " + filename): return false
		file.store_string(wire + "\n"); file.close()
		files[filename] = {"sha256": FileAccess.get_sha256(archive_path.path_join(filename)), "exact_wire_sha256": wire.sha256_text()}
	var pins: Dictionary = {}
	for path: String in O2_PINS:
		var digest: String = FileAccess.get_sha256(path)
		if not _expect(digest.length() == 64, "listed original O2 source pin exists: " + path): return false
		pins[path] = digest
	var manifest: Dictionary = {"schema_version": 1, "kind": "a3-o2-genuine-warning-session-1", "test_only": true, "adopted_baseline_commit": O2_ADOPTED, "git_provenance": "Exact native runner HEAD/dirty/input manifest governs execution; listed source_pins freeze actual bytes", "pins_scope": "listed authored/direct transport sources; native runner input manifest is independent authority", "fixture_sha256": FileAccess.get_sha256(O2_PINS[0]), "source_pins": pins, "files": files, "held_receipt": receipt, "test_context": "TEST prefix12/O2 readiness; unchanged actual accepted A3-L2 older Story opening; genuine first-court clear/CP1 and next Root warning, CP1 Retry; all five typed native sources; no court checkpoint/death/resource/history/clock/lease seed", "public_flow_validation": "pending; actual native runner closure is authoritative", "portrait_validation": "unexecuted; archive creates no pixels"}
	var wire: String = Exact.stringify(manifest)
	var file: FileAccess = FileAccess.open(archive_path.path_join("manifest.json"), FileAccess.WRITE)
	if not _expect(not wire.is_empty() and file != null, "finite original O2 warning provenance manifest opens"): return false
	file.store_string(wire + "\n"); file.close()
	print("O2 genuine warning archive: ", archive_path, "; manifest_sha256=", FileAccess.get_sha256(archive_path.path_join("manifest.json")))
	return true

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL O2 optional Shell: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok

func _finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(_o2_barrier):
		var observer_ref: WeakRef = weakref(_o2_barrier)
		if _o2_barrier.get("waiting"): _o2_barrier.call("_wake", "normal_finish")
		if _o2_barrier.get("presentation_waiting"): _o2_barrier.call("_wake_presentation", "normal_finish")
		_o2_barrier.queue_free(); _o2_barrier = null
		await _released([observer_ref], "normal native observer cleanup")
	await _dispose_shell()
	if is_instance_valid(preview):
		var refs: Array[WeakRef] = []
		_collect_refs(preview, refs)
		preview.queue_free(); preview = null
		await _released(refs, "remaining native Story seed cleanup")
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes, "canonical registry bytes unchanged by TEST O2 metadata")
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		if FileAccess.file_exists(isolated + filename): DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated + filename))
	AudioServer.set_bus_layout(old_audio)
	Engine.max_fps = old_fps
	var scope: String = "real CP1/CP2 latest Retry, four genuine Root primaries/third clear/stamp once, later native contact/protected Story, public Replay/dedup; no held-disk or portrait credit" if completion_return else "real first Root clear/CP1, actual second Root warning/Pause/format2 Save/fresh disk Side Resume/CP1 Retry/consumed GUI/early protected Story Journey; no CP2/final clear/stamp/contact-return/Replay/portrait credit"
	print("O2 Optional Shell: %d checks/%d failures; scope_complete=%s; selector=%s; %s; TEST prefix12/readiness only, actual direct public native actions, normal whole cleanup." % [checks, failures, str(scope_complete), "completion-return" if completion_return else "held-transport", scope])
	quit(0 if failures == 0 and scope_complete else 1)
