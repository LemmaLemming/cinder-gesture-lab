extends "res://tests/acts/act3/pillars_before_time_optional_shell.gd"
## O3 one-Echo/pulse prototype public Optional transport. Reuse only the unchanged
## accepted O1 generic Shell/ExactJson/GUI/quiet/identity/cleanup helpers.
## TEST ONLY O3 accepted metadata + prefix13; actual accepted A3-L2 Story packet.
## No Hero/resource/clock/history/death/lease/progress writes or court CP seed.
## This prototype proves no court clear, completion/stamp, contact return, replay,
## final three-court arrangement, portrait, earned route or human-input result.

const O3_PATH: String = "res://scenes/acts/act3/a3_o3_irontick_reflection.tscn"
const O3_ECHO: String = "o3-first-echo"
const O3_PULSE: String = "o3-first-pulse"
const O3_ADOPTED: String = "d180506738ebaa9774d791593dab70eaed618d05"
const O3_PINS: Array[String] = [
	"res://tests/acts/act3/irontick_reflection_optional_shell.gd",
	"res://tests/acts/act3/irontick_reflection_portrait.gd",
	"res://tests/acts/act3/pillars_before_time_optional_shell.gd",
	"res://scripts/acts/act3/irontick_reflection.gd",
	"res://scripts/acts/act3/irontick_reflection_codec.gd",
	"res://scenes/acts/act3/a3_o3_irontick_reflection.tscn",
	"res://data/campaign/act3/a3_o3_encounters.json",
	"res://scripts/acts/act3/mirror_echo.gd",
	"res://scripts/acts/act3/mirror_echo_codec2.gd",
	"res://scripts/acts/act3/mirror_echo_codec.gd",
	"res://scripts/acts/act3/mirror_echo_spent_marker.gd",
	"res://scripts/acts/act3/mirror_sea_scenery.gd",
	"res://scripts/acts/act3/twin_suns_scenery.gd",
	"res://assets/acts/act3/mirror_shore.gdshader",
	"res://scripts/combat/replay_playback.gd",
	"res://scripts/combat/replay_footprint.gd",
	"res://scripts/combat/replay_witness.gd",
	"res://scripts/combat/authored_enemy_sequence.gd",
	"res://scripts/combat/authored_echo_terminal_receipt.gd",
	"res://scripts/combat/authored_echo_cycle_journal.gd",
	"res://scripts/combat/lane_mechanism.gd",
	"res://scripts/combat/threat_scheduler.gd",
	"res://scripts/combat/body_sweep.gd",
	"res://scripts/combat/threat_geometry.gd",
	"res://scripts/campaign/shell.gd",
	"res://scripts/campaign/level.gd",
	"res://scripts/campaign/registry.gd",
	"res://scripts/campaign/attempts.gd",
	"res://scripts/campaign/save_store.gd",
	"res://scripts/campaign/exact_json.gd",
	"res://scripts/campaign/snapshot_codec.gd",
	"res://scripts/player.gd",
	"res://scripts/game.gd",
	"res://scripts/hud.gd",
	"res://scripts/ui/campaign_menu.gd",
	"res://scripts/equipment.gd",
	"res://data/design/player_equipment.json",
]

func _initialize() -> void:
	isolated = "user://test-a3-o3-optional-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	_run.call_deferred()

func _run() -> void:
	create_timer(150.0, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "bounded O3 prototype transport watchdog")
			_finish())
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	if not _expect(DisplayServer.get_name() == "headless" and OS.get_cmdline_user_args().is_empty(), "O3 prototype is explicit headless transport with no completion selector or portrait credit"):
		await _finish(); return
	var parsed: Variant = JSON.parse_string(canonical_bytes)
	if not _expect(parsed is Dictionary, "canonical registry loads read-only for isolated O3 metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for row: Dictionary in raw.levels:
		if row.id == "A3-O3":
			row.scene_path = O3_PATH
			row.readiness = "accepted"
			row.accepted_commit = "b".repeat(40) # TEST ONLY provenance, never integration acceptance.
			row.api_revision = Registry.API_REVISION
	var registry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A3-O3").is_empty() and registry.entry("A3-O3").parent_level_id == "A3-L3", "isolated O3 metadata keeps canonical parent/reward/route links", registry.last_error):
		await _finish(); return
	node_added.connect(_watch_node)
	print("O3 TEST ONLY prefix13/readiness; real native accepted A3-L2 older Story checkpoint, actual initial managed Echo warning, no fabricated court clear/CP/resources/history or earned-route claim.")
	if not await _seed_story(registry) or not await _new_shell(expected_session): await _finish(); return
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", protected): await _finish(); return
	if not _installed(protected) or not _quiet_selected(): await _finish(); return
	var old_story_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_story_refs)
	var old_story_ids: Dictionary = _core_ids()
	production.menu.optional_requested.emit("A3-O3")
	if not await _wait_installed("A3-O3", "resume", {}, old_story_ids): await _finish(); return
	var entrance: Dictionary = production.capture_campaign_snapshot()
	checkpoint = production.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _installed(entrance) or not await _released(old_story_refs, "Optional entry retires complete old Story world"): await _finish(); return
	if not _expect(production.attempts.active_kind() == "optional" and _same(checkpoint, entrance) and _same(production.attempts.state().story, expected_session.story) and not entrance.level.progress.completed and entrance.level.progress.checkpoint_ids.is_empty() and entrance.level.progress.contact_exit_id.is_empty() and entrance.level.progress.checkpoint_id.is_empty() and production.player.get_world_action_records().is_empty(), "actual O3 entry protects whole Story and its own pristine no-court-checkpoint entrance"):
		await _finish(); return
	var initial: Dictionary = production.active_level.call("state")
	if not _expect(entrance.level.local_snapshot_version == 1 and entrance.level.local.api_revision == "act3-irontick-reflection-pair-1" and initial.api_revision == "act3-irontick-reflection-1" and initial.echo.source_id == O3_ECHO and initial.echo.source_epoch == "A3-O3/o3-first-echo/own-sequence" and initial.echo.generation == 1 and initial.echo.hp == 36.0 and initial.echo.alive and initial.playback.status == "cycle_ready" and initial.pulse.status == "idle" and initial.pulse.cycle == 0 and initial.clock_s == 0.0, "actual prototype entrance retains native ready journal/36HP endpoint/idle pulse at clock0 without progression"):
		await _finish(); return
	if not await _resume_after_layout() or not await _wait_echo_warning(): await _finish(); return
	production.request_pause()
	if not await _wait_pause(): await _finish(); return
	held = production.capture_campaign_snapshot()
	var receipt: Dictionary = _held_receipt()
	if not _expect(not receipt.is_empty() and _same(production.attempts.active_snapshot(), held) and _same(production.attempts.state().side_attempt.checkpoint, checkpoint) and not _same(held, checkpoint) and held.level.progress.checkpoint_id.is_empty(), "public Pause saves actual Echo warning while prototype Retry remains exact entrance"):
		await _finish(); return
	if not _installed(held) or not _disk(production.attempts.state()) or not _archive_held(entrance, receipt): await _finish(); return
	var saved: Dictionary = production.attempts.state()
	var donor_ids: Dictionary = _native_ids()
	if not await _dispose_shell() or not await _new_shell(saved): await _finish(); return
	production.menu.resume_requested.emit() # Public Title Resume Side; Continue Story would abandon it.
	if not await _wait_installed("A3-O3", "resume", held): await _finish(); return
	if not _installed(held) or not _distinct(donor_ids) or not _quiet_selected(): await _finish(); return
	if not _expect(_same(_held_receipt(), receipt) and _same(production.attempts.state(), saved), "fresh disk Side Resume retains complete original managed Echo/pulse warning lease/cycle/clock/session"):
		await _finish(); return
	var old_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_refs)
	var old_ids: Dictionary = _native_ids()
	receiver_events.clear()
	production.menu.retry_requested.emit()
	if not await _wait_installed("A3-O3", "resume", checkpoint, old_ids): await _finish(); return
	if not _installed(checkpoint) or not _distinct(old_ids) or not _quiet_selected() or not await _released(old_refs, "entrance Retry frees original whole Echo/Mechanism/field/floor world"):
		await _finish(); return
	if not _expect(_same(production.attempts.active_snapshot(), checkpoint) and _same(production.attempts.state().side_attempt.checkpoint, checkpoint) and _same(production.attempts.state().story, expected_session.story), "public Retry restores actual pristine entrance without invented court CP or Story refresh"):
		await _finish(); return
	if not _disk(production.attempts.state()) or not await _gui_resume(checkpoint): await _finish(); return
	old_refs.clear()
	_collect_refs(_world_container(), old_refs)
	var before_leave: Dictionary = _core_ids()
	production.menu.leave_side_requested.emit()
	if not await _wait_installed(STORY_ID, "journey", protected, before_leave): await _finish(); return
	if not _installed(protected) or not await _released(old_refs, "early Leave Side retires complete optional Echo world"): await _finish(); return
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
	expected_session.completed_main = registry.main_route().slice(0, 13)
	var detached = Attempts.new(registry)
	var error: String = detached.state_error(expected_session)
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = detached.saved_payload_error
	if not _expect(error.is_empty() and expected_session.completed_main[-1] == "A3-L3" and packet_before == Exact.stringify(protected) and _same(expected_session.story.snapshot, protected) and _same(expected_session.story.checkpoint, protected) and writer.write_payload(expected_session), "validated detached TEST prefix13 preserves genuine older A3-L2 Story/actor/local/input/camera packet byte-exact", error + "; " + writer.last_error): return false
	return _disk(expected_session)

func _wait_echo_warning() -> bool:
	for _frame: int in range(LIVE_FRAME_LIMIT):
		await process_frame
		if not _valid_shell() or production.player.dead: return _expect(false, "native Echo warning wait retains living actual Hero")
		if paused: continue
		if not _held_receipt().is_empty(): return _expect(true, "actual managed Echo publishes its initial unarmed native warning")
	return _expect(false, "bounded genuine initial Echo warning admission", str(production.active_level.call("state")))

func _held_receipt() -> Dictionary:
	var level: CinderLevel = production.active_level
	var echo: Node3D = level.get("echo") as Node3D
	var pulse: CinderLaneMechanism = level.get("mechanism") as CinderLaneMechanism
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	if not is_instance_valid(echo) or not is_instance_valid(pulse) or not is_instance_valid(scheduler): return {}
	var actor: Dictionary = echo.call("get_source_state")
	var playback: Dictionary = echo.call("state")
	var control: Dictionary = scheduler.source_control_state(echo)
	var bindings: Dictionary = level.call("scheduler_bindings")
	if actor.get("source_id") != O3_ECHO or actor.get("phase") != "warning" or actor.get("alive") != true or playback.get("status") != "running" or String(playback.get("reservation_id", "")).is_empty() or not playback.get("cursor") is Dictionary or playback.cursor.get("armed") != false or control.get("reservations", []).size() != 1: return {}
	var lease: Dictionary = control.reservations[0]
	if not lease.get("adapter") is Dictionary or lease.adapter.get("kind") != "authored_replay" or lease.adapter.get("locked") != false or lease.get("id") != playback.reservation_id or lease.get("state") != "warning" or not lease.get("lock_from_s") is float or scheduler.get_clock() >= float(lease.lock_from_s): return {}
	if bindings.owners.get(O3_ECHO) != echo or bindings.owners.get(O3_PULSE) != pulse or control.source_instance_id != echo.get_instance_id() or int(lease.source_instance_id) != echo.get_instance_id() or int(lease.response_actor_instance_id) != production.player.get_instance_id() or control.clock_s != scheduler.get_clock() or actor.clock_s != scheduler.get_clock() or actor.generation != playback.generation or not echo.call("source_cycles_managed"): return {}
	var pulse_state: Dictionary = pulse.state()
	return {"source_id": O3_ECHO, "source_epoch": actor.source_epoch, "generation": actor.generation, "playback_id": playback.playback_id, "phase": "warning", "reservation_id": playback.reservation_id, "armed": false, "clock_s": scheduler.get_clock(), "hp": actor.hp, "alive": actor.alive, "pulse_status": pulse_state.status, "pulse_phase": pulse_state.phase, "pulse_cycle": pulse_state.cycle}

func _native_ids() -> Dictionary:
	var result: Dictionary = _core_ids()
	var level: CinderLevel = production.active_level
	var echo: Node3D = level.get("echo") as Node3D
	var pulse: CinderLaneMechanism = level.get("mechanism") as CinderLaneMechanism
	result.scheduler = (level.get("threat_scheduler") as Node).get_instance_id()
	result.source = echo.get_instance_id()
	result.echo = echo.get_instance_id()
	result.renderer = (echo.call("get_authored_echo_renderer") as Node).get_instance_id()
	result.pulse = pulse.get_instance_id()
	result.pulse_cue = pulse.get_cue().get_instance_id()
	result.scenery = (level.get("scenery") as Node).get_instance_id()
	result.reflection = level.get_node("HarmlessOutlinedReflection").get_instance_id()
	var bindings: Dictionary = level.call("scheduler_bindings")
	for id: String in bindings.owners: result["owner/" + id] = (bindings.owners[id] as Node).get_instance_id()
	for id: String in bindings.floors:
		var collision: CollisionShape3D = bindings.floors[id].collision
		result["collision/" + id] = collision.get_instance_id()
		result["floor/" + id] = collision.get_parent().get_instance_id()
	return result

func _archive_held(entrance: Dictionary, receipt: Dictionary) -> bool:
	if not _expect(paused and receipt.get("phase") == "warning" and _same(production.capture_campaign_snapshot(), held) and _same(production.attempts.active_snapshot(), held), "archive only genuine paused Echo warning and complete native active session"): return false
	archive_path = "res://captures/act3/irontick-reflection/optional-held-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(archive_path)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(archive_path)) == OK, "new O3 archive preserves all prior originals"): return false
	var values: Dictionary = {"session.native.json": production.attempts.state(), "held.native.json": held, "entrance.native.json": entrance, "checkpoint.native.json": checkpoint, "story.native.json": protected, "start-session.native.json": expected_session, "registry.native.json": raw}
	var files: Dictionary = {}
	for filename: String in values:
		var wire: String = Exact.stringify(values[filename])
		var file: FileAccess = FileAccess.open(archive_path.path_join(filename), FileAccess.WRITE)
		if not _expect(not wire.is_empty() and file != null, "complete finite native O3 archive file opens: " + filename): return false
		file.store_string(wire + "\n"); file.close()
		files[filename] = {"sha256": FileAccess.get_sha256(archive_path.path_join(filename)), "exact_wire_sha256": wire.sha256_text()}
	var pins: Dictionary = {}
	for path: String in O3_PINS:
		var digest: String = FileAccess.get_sha256(path)
		if not _expect(digest.length() == 64, "listed original O3 source pin exists: " + path): return false
		pins[path] = digest
	var manifest: Dictionary = {"schema_version": 1, "kind": "a3-o3-genuine-warning-session-1", "test_only": true, "adopted_baseline_commit": O3_ADOPTED, "shared_api": "campaign-shared-62", "shared_publication": "e4405c678603e5e7c0e09de49285cad752f5b812", "git_provenance": "Exact native runner HEAD/dirty/input manifest governs execution; listed source_pins freeze actual bytes", "pins_scope": "listed authored/direct transport sources; native runner input manifest is independent authority", "fixture_sha256": FileAccess.get_sha256(O3_PINS[0]), "source_pins": pins, "files": files, "held_receipt": receipt, "test_context": "TEST prefix13/O3 readiness; unchanged actual accepted A3-L2 older Story opening; genuine first Echo warning, entrance Retry; no court checkpoint/death/resource/history/clock/lease seed", "public_flow_validation": "pending; actual native runner closure is authoritative", "portrait_validation": "unexecuted; archive creates no pixels"}
	var wire: String = Exact.stringify(manifest)
	var file: FileAccess = FileAccess.open(archive_path.path_join("manifest.json"), FileAccess.WRITE)
	if not _expect(not wire.is_empty() and file != null, "finite original O3 warning provenance manifest opens"): return false
	file.store_string(wire + "\n"); file.close()
	print("O3 genuine warning archive: ", archive_path, "; manifest_sha256=", FileAccess.get_sha256(archive_path.path_join("manifest.json")))
	return true

func _watch_node(node: Node) -> void:
	if not is_instance_valid(production) or not production.is_ancestor_of(node) or watched.has(node.get_instance_id()): return
	watched[node.get_instance_id()] = true
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired", "died", "action_resolved", "world_action_executed", "hit_resolved", "source_hit_resolved", "source_defeated", "event_dispatched", "checkpoint_requested", "completion_requested", "contact_exit_requested"] and row.args.size() <= 3:
			node.connect(row.name, Callable(self, "_event" + str(row.args.size())).bind(str(node.get_instance_id()), String(row.name)))

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL O3 optional Shell: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok

func _finish() -> void:
	if finished: return
	finished = true
	await _dispose_shell()
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal Optional cleanup releases all source/cue groups")
	if is_instance_valid(preview):
		var refs: Array[WeakRef] = []
		_collect_refs(preview, refs)
		preview.queue_free(); preview = null
		await _released(refs, "remaining native Story seed cleanup")
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes, "canonical registry bytes unchanged by TEST O3 metadata")
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		if FileAccess.file_exists(isolated + filename): DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated + filename))
	AudioServer.set_bus_layout(old_audio)
	Engine.max_fps = old_fps
	print("O3 prototype Optional Shell: %d checks/%d failures; scope_complete=%s; actual Echo warning/Pause/format2 Save/fresh disk Side Resume/entrance Retry/GUI Resume/early protected Story Journey/normal cleanup. TEST prefix13/readiness only; no stage CP/clear, completion/stamp, contact return, Replay, final arrangement, portrait or earned-route credit." % [checks, failures, str(scope_complete)])
	quit(0 if failures == 0 and scope_complete else 1)
