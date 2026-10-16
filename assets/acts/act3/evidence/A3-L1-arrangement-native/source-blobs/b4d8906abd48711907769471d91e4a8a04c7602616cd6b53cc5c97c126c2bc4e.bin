extends "res://tests/acts/act3/twin_suns_production_transition_smoke.gd"
## Original-only MAIN Story producer. SOURCE-ONLY until Root imports/runs it.
## TEST prefix10 and a disclosed existing predecessor floor enable public fresh
## Challenge entry; no L1 route/HP/pose/clock/resource/source history is seeded.
## Output is immutable old API1/schema1/local5/native-source3 data, not new-reader
## acceptance. Raw native format2 Store files are copied without reencoding.

const PRODUCER_PATH: String = "res://tests/acts/act3/twin_suns_arrangement_smoke.gd"
const FIXTURE_ROOT: String = "res://tests/acts/act3/fixtures/a3_l1_arrangement_legacy"
const ORIGINAL_RUNTIME_SHA256: String = "17ae090ea809c3170aef76e8393b0b2edde9f85b719dff2b7e55edfca9499247"
const AttemptsModel = preload("res://scripts/campaign/attempts.gd")
const GameModel = preload("res://scripts/game.gd")
const OLD_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route"]
const OLD_ORIGINS: Dictionary = {
	"l1-flank-stalker": Vector3(1.6,0.1,25),
	"l1-approach-stalker": Vector3(-1.8,0.1,3),
	"l1-crossing-west": Vector3(-2.2,0.1,-14),
	"l1-crossing-east": Vector3(2.2,0.1,-17),
	"l1-departure-stalker": Vector3(1.2,0.1,-35),
}
var _producer_done: bool = false
var _producer_complete: bool = false
var _producer_raw: Dictionary = {}
var _producer_seed: Dictionary = {}
var _producer_entrance: Dictionary = {}
var _producer_origins: Dictionary = {}
var _producer_pins: Dictionary = {}
var _producer_uids: Dictionary = {}
var _producer_files: Dictionary = {}
var _producer_samples: Dictionary = {}
var _producer_ticks: int = 0

func _initialize() -> void:
	# Do not inherit the historical driver's runtime UID creation helper.
	_profile_id = "challenge"
	_side = -1
	_tick_barrier = PostActorPhysicsBarrier.new()
	_tick_barrier.name = "OriginalL1PostActorBarrier"
	_tick_barrier.process_mode = Node.PROCESS_MODE_PAUSABLE
	_tick_barrier.process_physics_priority = 1000
	root.add_child(_tick_barrier)
	_run.call_deferred()
	create_timer(600.0,true,false,true).timeout.connect(_producer_watchdog)

func _run() -> void:
	if not _expect(OS.get_cmdline_user_args() == PackedStringArray(["--produce-legacy"]), "only explicit original producer selector is supported"):
		await _producer_finish(); return
	if not _expect(FileAccess.get_sha256(RuntimePath) == ORIGINAL_RUNTIME_SHA256 and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT)), "authentic original runtime and new archive path required; never overwrite history"):
		await _producer_finish(); return
	var catalogue: CinderEquipment = EquipmentScript.new()
	catalogue.reset_starter()
	_kit = catalogue.snapshot()
	_stats = catalogue.resolved_stats()
	_test_root = "user://test-a3-l1-original-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_canonical_bytes = FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(_canonical_bytes)
	if not _expect(parsed is Dictionary, "actual canonical registry is readable"):
		await _producer_finish(); return
	_producer_raw = parsed.duplicate(true)
	# Only predecessor scene is TEST. L1 remains its actual accepted MAIN row.
	for row: Dictionary in _producer_raw.levels:
		if row.id == "A2-L5": row.scene_path = PredecessorFixturePath
	var registry := ProductionRegistry.new(_producer_raw)
	_prefix.assign(registry.main_route().slice(0,10))
	if not _expect(registry.last_error.is_empty() and _prefix.size() == 10 and _prefix[-1] == "A2-L5" and registry.entry("A3-L1").scene_path == FullPath, "TEST predecessor prefix10 leaves actual L1 MAIN identity unchanged",registry.last_error):
		await _producer_finish(); return
	var predecessor: Dictionary = await _producer_predecessor()
	if predecessor.is_empty() or not _producer_capture_pins(): await _producer_finish(); return
	var model := AttemptsModel.new(registry)
	_producer_seed = model.state()
	_producer_seed.completed_main = _prefix.duplicate() # Explicit TEST metadata only.
	_producer_seed.story = {"kind":"story","level_id":"A2-L5","snapshot":predecessor.duplicate(true),"checkpoint":predecessor.duplicate(true)}
	var store := ProductionStore.new(_test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(_producer_seed).is_empty() and store.write_payload(_producer_seed), "structurally validated TEST predecessor seed wraps genuine native writers unchanged",model.last_error+"; "+store.last_error):
		await _producer_finish(); return
	_shell = ProductionShell.new()
	_game = _shell
	if not _expect(_shell.configure_runtime(_producer_raw,_test_root+"campaign.json",_test_root+"settings.json",_test_root+"preferences.json"), "actual production Shell uses isolated paths"):
		await _producer_finish(); return
	root.add_child(_shell)
	if not await _producer_settle("title",false): await _producer_finish(); return
	_shell.menu.show_settings()
	var selector := _shell.menu.find_child("DifficultySelector",true,false) as OptionButton
	if not _expect(is_instance_valid(selector), "actual public menu exposes canonical difficulty selection"):
		await _producer_finish(); return
	var selected: int = -1
	for i: int in range(selector.item_count):
		if selector.get_item_metadata(i) == "challenge": selected = i
	if not _expect(selected >= 0, "canonical Challenge option exists"):
		await _producer_finish(); return
	selector.select(selected)
	selector.item_selected.emit(selected)
	var preference := ProductionStore.new(_test_root+"preferences.json")
	if not _expect(_shell.get_difficulty_preference() == "challenge" and _exact(preference.read_payload(),{"schema_version":1,"profile_id":"challenge"}) and _exact(_shell.attempts.state(),_producer_seed), "public menu persists future Challenge without changing the genuine predecessor unit"):
		await _producer_finish(); return
	_shell.resume_campaign()
	if not await _producer_settle("resume",true): await _producer_finish(); return
	if not _expect(_shell.active_level.level_id == "A2-L5" and _exact(_shell.capture_campaign_snapshot(),predecessor), "public Continue installs only the disclosed predecessor floor"):
		await _producer_finish(); return
	if not _expect(_shell.active_level.request_completion("test-only-predecessor-clear"), "existing TEST predecessor public completion is accepted"):
		await _producer_finish(); return
	if not await _producer_settle("resume",true): await _producer_finish(); return
	if not _expect(_shell.active_level.is_completed() and _shell.attempts.state().completed_main == _prefix, "TEST predecessor completes without advancing the declared prefix"):
		await _producer_finish(); return
	if not _expect(_shell.active_level.request_contact_exit("test-only-fresh-challenge-entry",_shell.player), "TEST predecessor public contact creates fresh MAIN L1"):
		await _producer_finish(); return
	if not await _producer_settle("resume",true,"A3-L1"): await _producer_finish(); return
	_hero = _shell.player
	_level = _shell.active_level
	var error: String = _bind_runtime()
	if not _expect(error.is_empty(), "actual five-source Challenge/floor/Hero runtime binds",error):
		await _producer_finish(); return
	_hp_before = _hero.hp
	_topology = _world_topology()
	_route_deadline = 70.0
	_producer_entrance = _shell.capture_campaign_snapshot()
	for id: String in SourceIds: _producer_origins[id] = Codec.vector3((_sources[id] as Node3D).global_position)
	if not _producer_unit(_producer_entrance,false) or not _producer_prepare_archive() or not _producer_archive("entrance",_producer_entrance,{}): await _producer_finish(); return
	print("Twin Suns original producer: authentic Challenge entrance archived")
	_shell.resume_lab()
	if not _expect(not paused,"public production resume starts genuine first-entry approach"):
		await _producer_finish(); return
	error = await _travel_entry(0)
	if not _expect(error.is_empty(), "unchanged ordinary first-entry route reaches actual latest checkpoint",error):
		await _producer_finish(); return
	var held: Dictionary = {}
	for _tick: int in range(_frame_limit(WarningBudgetS)):
		var state: Dictionary = _sources[SourceIds[0]].state()
		if state.phase == "warning" and not String(state.reservation_id).is_empty():
			_shell.request_pause()
			if not await _producer_settle("pause",true,"A3-L1"): await _producer_finish(); return
			held = _shell.capture_campaign_snapshot()
			break
		error = await _tick_safe()
		if not error.is_empty(): break
	if not _expect(error.is_empty() and not held.is_empty(), "first real C50 warning is observed and paused without any attack",error+"; "+_diagnostic()):
		await _producer_finish(); return
	var receipt: Dictionary = _producer_warning_receipt()
	if not _expect(not receipt.is_empty(), "paused first held warning retains actual source/lease/phase/deadlines") or not _producer_unit(held,true) or not _producer_archive("first-stalker-held",held,receipt):
		await _producer_finish(); return
	for path: String in _producer_pins:
		if not _expect(FileAccess.get_sha256(path) == _producer_pins[path], "producer original source/UID remains exact: "+path): await _producer_finish(); return
	if not _producer_write("manifest.json",{"schema_version":1,"kind":"a3-l1-original-challenge-arrangement-legacy-1","test_only":true,"files":_producer_files.duplicate(true),"source_pins":_producer_pins,"resource_uid_text":_producer_uids,"samples":_producer_samples,"observed_entrance_origins":_producer_origins,"native_observations":_producer_ticks,"canonical_registry_sha256":FileAccess.get_sha256(ProductionRegistry.DATA_PATH),"scope":"Actual old Challenge MAIN Story entrance and first held C50 warning, genuine latest first-entry checkpoint/raw format2 Stores; TEST prefix10/predecessor floor only. No crossing approach/kill/completion/contact/new reader or full-route credit. Original canonical runner command/source/result/log supplies execution HEAD and closure."}):
		await _producer_finish(); return
	_producer_complete = true
	await _producer_finish()

func _producer_predecessor() -> Dictionary:
	paused = true
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path",PredecessorFixturePath)
	root.add_child(preview)
	preview.call("open_bench")
	await process_frame
	var actor := preview.get("player") as CinderPlayer
	var level := preview.get("active_level") as CinderLevel
	var camera := preview.get("camera") as Camera3D
	var result: Dictionary = {}
	if _expect(is_instance_valid(actor) and is_instance_valid(level) and is_instance_valid(camera) and level.level_id == "A2-L5", "existing native TEST predecessor constructs through actual Main"):
		var actor_state: Dictionary = actor.snapshot_state()
		var local: Dictionary = level.snapshot_state()
		var input: Dictionary = preview.call("get_input_observation_state")
		if _expect(not actor_state.is_empty() and not local.is_empty() and actor.get_world_action_clock() == 0.0 and actor.get_world_action_records().is_empty() and input.sequence == 0, "predecessor native writers are genuinely initial; no live resource/pose/clock mutation",actor.last_snapshot_error+"; "+level.last_snapshot_error):
			var anchor: Vector2 = input.anchor_normalized
			var shell_state: Dictionary = {"api_revision":ProductionShell.SHELL_API,"anchor_normalized":[anchor.x,anchor.y],"input_sequence":input.sequence,"last_input_observation":{},"camera_focus":Codec.vector3(camera.global_position-GameModel.CAMERA_OFFSET),"shake_left_s":0.0,"difficulty_at_entry":"standard"}
			result = {"schema_version":1,"level_id":"A2-L5","scene_path":PredecessorFixturePath,"paused":true,"equipment_ids":actor.equipment.snapshot(),"player":actor_state,"level":local,"shell":shell_state}
	if is_instance_valid(level): level.exit_level()
	preview.queue_free()
	for _frame: int in range(6): await process_frame
	return result

func _producer_settle(page: String, installed: bool, id: String = "") -> bool:
	for _frame: int in range(120):
		await process_frame
		if not _expect(is_instance_valid(_shell) and _shell.campaign_error.is_empty(),"public producer operation retains no campaign refusal",_shell.campaign_error if is_instance_valid(_shell) else "Shell freed"): return false
		if paused and _shell.menu.page_name() == page and (not installed or (is_instance_valid(_shell.player) and is_instance_valid(_shell.active_level) and (id.is_empty() or _shell.active_level.level_id == id))):
			# Observe one additional ordinary paused UI/deferred boundary; do not
			# write Shell operation flags or manually advance any actor.
			await process_frame
			return _expect(paused and _shell.campaign_error.is_empty() and _shell.menu.page_name() == page,"public paused operation settles its actual menu/lifecycle",_shell.campaign_error)
	return _expect(false,"public producer operation exceeds bounded120 process observations",str({"page":page,"actual":_shell.menu.page_name(),"paused":paused,"campaign_error":_shell.campaign_error}))

func _tick_safe() -> String:
	_producer_ticks += 1
	if _producer_ticks > 2400: return "first-warning producer exceeded bounded2400 observations"
	return await super._tick_safe()

func _producer_unit(unit: Dictionary, held: bool) -> bool:
	if not _expect(not unit.is_empty() and paused and unit.level_id == "A3-L1" and unit.scene_path == FullPath and unit.shell.difficulty_at_entry == "challenge" and unit.level.local_snapshot_version == 5,"genuine old Challenge MAIN whole unit retains outer local5"): return false
	var local: Dictionary = unit.level.local
	if not _expect(Codec.keys_error(local,OLD_KEYS).is_empty() and local.api_revision == "act3-twin-suns-level-1" and local.schema_version == 1 and local.scheduler.schema_version == 1 and local.scheduler.profile.id == "challenge" and local.scheduler.world_revision == 1 and local.scheduler.encounter_id == "A3-L1/full-route" and Codec.keys_error(local.sources,SourceIds).is_empty() and local.route.deaths.is_empty() and local.route.exit_state == "clear" and local.route.contact.is_empty() and not unit.level.progress.completed,"literal old API1/schema1 six keys/world1 with all five source3 actors and no synthetic clear"): return false
	if not _expect(local.route.entries.size() == (1 if held else 0) and unit.level.progress.checkpoint_id == (CheckpointIds[0] if held else "") and unit.level.progress.checkpoint_ids.size() == (1 if held else 0),"actual MAIN checkpoint is latest first-entry only, never optional entrance policy"): return false
	for id: String in SourceIds:
		var actor: Dictionary = local.sources[id]
		if not _expect(actor.api_revision == "act3-stalker-snapshot-3" and actor.schema_version == 3 and actor.stable_id == id and actor.resolved_role.difficulty_profile == "challenge" and not actor.dead and actor.hp == actor.max_hp and _exact(_producer_origins[id],Codec.vector3(OLD_ORIGINS[id])),"all original native identities/initial origins/Challenge roles are observed: "+id): return false
		# The actual entered C50 can approach before it warns. Its current pose
		# is native-owned; only dormant future actors remain at original home.
		if not held or id != SourceIds[0]:
			if not _expect(Codec.read_vector3(actor.position) == OLD_ORIGINS[id] and actor.cycle == 0 and actor.reservation_id.is_empty(),"untouched source is at its real original origin: "+id): return false
	if not held:
		return _expect(local.scheduler.clock_s == 0.0 and unit.player.world_actions.clock_s == 0.0 and unit.player.world_actions.history.is_empty(),"fresh Challenge zero-clock entrance carries no L1 gameplay")
	return _expect(_actions.size() > 0 and int(_events.get("fired_blast",0)) == 0 and int(_events.get("fired_slash",0)) == 0 and _hero.hp == _hp_before,"held sample uses real ordinary approach dashes with no attack/damage/resource edits")

func _producer_warning_receipt() -> Dictionary:
	var source: CinderAct3SunboundStalker = _sources[SourceIds[0]]
	var state: Dictionary = source.state()
	var control: Dictionary = _scheduler.source_control_state(source)
	if state.phase != "warning" or String(state.reservation_id).is_empty() or control.get("reservations",[]).size() != 1: return {}
	var lease: Dictionary = control.reservations[0]
	if lease.id != state.reservation_id or state.stable_id != SourceIds[0] or control.source_instance_id != source.get_instance_id() or lease.source_instance_id != source.get_instance_id() or not lease.armed or lease.state != "warning" or lease.profile_id != "challenge" or lease.adapter.kind != "lunge" or state.clock_s != _scheduler.get_clock() or _scheduler.get_clock() >= float(lease.lock_from_s): return {}
	var deadlines: Dictionary = {}
	for key: String in FixedDeadlines: deadlines[key] = lease[key]
	return {"source_id":SourceIds[0],"phase":"warning","reservation_id":lease.id,"cycle":state.cycle,"clock_s":_scheduler.get_clock(),"current_source_position":Codec.vector3(source.global_position),"deadlines":deadlines,"actual_source_instance_id_decimal_text":str(source.get_instance_id())}

func _producer_prepare_archive() -> bool:
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT)) == OK,"new original fixture root is created once"): return false
	return _producer_write("registry.native.json",_producer_raw) and _producer_write("start-session.native.json",_producer_seed) and _producer_write("source-pins.json",{"source_pins":_producer_pins,"resource_uid_text":_producer_uids})

func _producer_archive(label: String, unit: Dictionary, receipt: Dictionary) -> bool:
	var session: Dictionary = _shell.attempts.state()
	var checkpoint: Dictionary = session.story.checkpoint
	if not _expect(_exact(session.story.snapshot,unit) and session.story.level_id == "A3-L1" and session.side_attempt == null and session.completed_main == _prefix and _exact(_shell.capture_campaign_snapshot(),unit),"actual full MAIN session joins current native unit: "+label): return false
	if not _expect((checkpoint.level.progress.checkpoint_id == CheckpointIds[0] and checkpoint.level.local.route.entries.size() == 1) if label == "first-stalker-held" else _exact(checkpoint,unit),"protected checkpoint follows actual latest entry, not always entrance: "+label): return false
	var reader := ProductionStore.new(_test_root+"campaign.json")
	if not _expect(_exact(reader.read_payload(),session) and reader.last_error.is_empty() and not reader.loaded_backup,"independent native primary format2 Store equals full actual MAIN session: "+label,reader.last_error): return false
	var folder: String = FIXTURE_ROOT.path_join(label)
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"new sample directory opens: "+label): return false
	if not _producer_write(label+"/unit.native.json",unit) or not _producer_write(label+"/session.native.json",session) or not _producer_write(label+"/checkpoint.native.json",checkpoint): return false
	for file: String in ["campaign.json","preferences.json"]:
		if not _producer_copy_raw(label+"/"+("campaign.store.json" if file == "campaign.json" else "preferences.store.json"),_test_root+file): return false
	if FileAccess.file_exists(_test_root+"campaign.json.bak"):
		if not _producer_copy_raw(label+"/campaign.store.json.bak",_test_root+"campaign.json.bak"): return false
	var ids: Dictionary = {"shell":str(_shell.get_instance_id()),"world":str(_shell.world.get_instance_id()),"player":str(_hero.get_instance_id()),"level":str(_level.get_instance_id()),"scheduler":str(_scheduler.get_instance_id()),"camera":str(_shell.camera.get_instance_id())}
	for id: String in SourceIds: ids[id] = str((_sources[id] as Node).get_instance_id())
	if not _producer_write(label+"/receipt.json",{"schema_version":1,"test_only":true,"sample":label,"observed_entrance_origins":_producer_origins,"held_warning":receipt,"native_ids_decimal_text":ids,"whole_exact_sha256":ExactJson.stringify(unit).sha256_text(),"session_exact_sha256":ExactJson.stringify(session).sha256_text(),"raw_store_policy":"Original native format2 bytes copied directly, never parsed/reencoded."}): return false
	_producer_samples[label] = {"unit":label+"/unit.native.json","session":label+"/session.native.json","checkpoint":label+"/checkpoint.native.json","receipt":label+"/receipt.json"}
	return _expect(_exact(_shell.capture_campaign_snapshot(),unit) and _exact(_shell.attempts.state(),session),"archival filesystem writes leave native whole unit/session unchanged: "+label)

func _producer_capture_pins() -> bool:
	var paths: Array[String] = [PRODUCER_PATH,RuntimePath,FullPath,"res://scripts/acts/act3/twin_suns.gd","res://scripts/acts/act3/twin_suns_scenery.gd","res://scripts/acts/act3/sunbound_stalker.gd","res://scripts/acts/act3/stalker_art.gd","res://data/campaign/act3/a3_l1_encounters.json","res://scripts/campaign/shell.gd","res://scripts/campaign/level.gd","res://scripts/campaign/attempts.gd","res://scripts/campaign/save_store.gd","res://scripts/campaign/exact_json.gd","res://scripts/campaign/snapshot_codec.gd","res://scripts/combat/threat_scheduler.gd","res://scripts/combat/difficulty.gd","res://data/design/difficulty_profiles.json","res://scripts/player.gd","res://tests/acts/act3/twin_suns_level_smoke.gd","res://tests/acts/act3/twin_suns_production_transition_smoke.gd",PredecessorFixturePath,"res://tests/fixtures/campaign/live_a1_l2.tscn","res://tests/fixtures/campaign/live_level.gd",ProductionRegistry.DATA_PATH]
	for path: String in paths:
		var sha: String = FileAccess.get_sha256(path)
		if not _expect(sha.length() == 64,"original source exists for custody: "+path): return false
		_producer_pins[path] = sha
		if FileAccess.file_exists(path+".uid"):
			_producer_pins[path+".uid"] = FileAccess.get_sha256(path+".uid")
			_producer_uids[path] = FileAccess.get_file_as_string(path+".uid").strip_edges()
		elif path.ends_with(".tscn"):
			var uid: int = ResourceLoader.get_resource_uid(path)
			if uid != ResourceUID.INVALID_ID: _producer_uids[path] = ResourceUID.id_to_text(uid)
	return _expect(FileAccess.file_exists(PRODUCER_PATH+".uid"),"new fixture UID must come from legitimate Root import before execution")

func _producer_write(relative: String, value: Dictionary) -> bool:
	var target: String = FIXTURE_ROOT.path_join(relative)
	var wire: String = ExactJson.stringify(value)
	if not _expect(not wire.is_empty() and not FileAccess.file_exists(target),"bounded finite new ExactJSON archive: "+relative): return false
	var file := FileAccess.open(target,FileAccess.WRITE)
	if not _expect(file != null,"archive file opens: "+relative): return false
	file.store_string(wire+"\n")
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if not _expect(error == OK and FileAccess.get_file_as_string(target) == wire+"\n","exact archive persists unchanged: "+relative): return false
	_producer_files[relative] = {"sha256":FileAccess.get_sha256(target),"bytes":FileAccess.get_file_as_bytes(target).size(),"exact_wire_sha256":wire.sha256_text()}
	return true

func _producer_copy_raw(relative: String, source: String) -> bool:
	var target: String = FIXTURE_ROOT.path_join(relative)
	var sha: String = FileAccess.get_sha256(source)
	if not _expect(sha.length() == 64 and not FileAccess.file_exists(target) and DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(target)) == OK and FileAccess.get_sha256(target) == sha and FileAccess.get_sha256(source) == sha,"native raw Store byte copy: "+relative): return false
	_producer_files[relative] = {"sha256":sha,"bytes":FileAccess.get_file_as_bytes(target).size(),"original_user_path":source,"raw_store_copy":true}
	return true

func _producer_watchdog() -> void:
	if _producer_done: return
	_expect(false,"producer bounded600-second host watchdog expired; archive remains partial")
	await _producer_finish()

func _producer_finish() -> void:
	if _producer_done: return
	_producer_done = true
	# Public exit runs before any source leaves its tree; no silent cancel or
	# fabricated history cleanup. Archive bytes remain even for partial failure.
	if is_instance_valid(_level) and _level.is_inside_tree(): _level.exit_level()
	await _dispose()
	print("Twin Suns arrangement original producer: %d checks/%d failures; complete=%s; observations=%d; MAIN Story only, no new-reader/crossing/full-route credit." % [_checks,_failures,str(_producer_complete),_producer_ticks])
	quit(0 if _failures == 0 and _producer_complete else 1)
