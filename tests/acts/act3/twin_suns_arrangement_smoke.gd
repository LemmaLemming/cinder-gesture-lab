extends "res://tests/acts/act3/twin_suns_production_transition_smoke.gd"
## Focused original MAIN Story producer, retained-map transport and crossing trial.
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
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--crossing-compare", "--crossing-portrait"]:
		_lt_defaults()
		var writer: Callable = _lp_portrait if args[0] == "--crossing-portrait" else Callable()
		_producer_complete = await _lc_run(args[0],writer)
		await _producer_finish()
		return
	if args.size() == 1 and args[0] in ["--legacy", "--current-persistence", "--pure"]:
		var ok: bool = false
		if args[0] == "--legacy": ok = await _lt_run_legacy()
		elif args[0] == "--current-persistence": ok = await _lt_run_current_persistence()
		else: ok = _lt_run_pure()
		_producer_complete = ok
		await _producer_finish()
		return
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
	if _lc_running: return await _lc_tick_safe()
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
	if _lc_running or is_instance_valid(_game) and _game != _shell and _lc_scene != null:
		var component_cleanup: String = await _lc_dispose()
		_expect(component_cleanup.is_empty(),"common final/watchdog component retirement",component_cleanup)
	# Public exit runs before any source leaves its tree; no silent cancel or
	# fabricated history cleanup. Archive bytes remain even for partial failure.
	if is_instance_valid(_level) and _level.is_inside_tree(): _level.exit_level()
	await _dispose()
	print("Twin Suns arrangement: %d checks/%d failures; complete=%s; observations=%d; selector=%s; explicit producer/pure/MAIN transport scope only, no full-route credit." % [_checks,_failures,str(_producer_complete),_producer_ticks,str(OS.get_cmdline_user_args())])
	quit(0 if _failures == 0 and _producer_complete else 1)


## PRIVATE SOURCE-ONLY appendable fragment for twin_suns_arrangement_smoke.gd.
## Compose only AFTER original producer closes and its manifest is sealed.
## No new resource, scene, production method, optional attempt or synthetic route.
## See /private/tmp/L1_ARRANGEMENT_TRANSPORT_INTEGRATION.md for dispatcher hooks.
const LT_Runtime = preload("res://scripts/acts/act3/twin_suns_level.gd")
const LT_Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
# Actual clean original producer03, sealed at b4daffbbf4e184b7b1c9653bb84d50eda3337067.
const LT_LEGACY_MANIFEST_SHA256: String = "0a4855183ff759c156ba00f9337d7b977272efb1a71c59224c01dce17d68dd40"
const LT_NEW_KEYS: Array[String] = ["api_revision","schema_version","scenery","scheduler","sources","route","arrangement"]
const LT_CHALLENGE_STARTS: Dictionary = {
	"l1-flank-stalker":Vector3(1.6,0.1,25), "l1-approach-stalker":Vector3(-1.8,0.1,3),
	"l1-crossing-west":Vector3(-2.2,0.1,-17), "l1-crossing-east":Vector3(2.2,0.1,-14),
	"l1-departure-stalker":Vector3(1.2,0.1,-35),
}
var _lt_manifest: Dictionary = {}
var _lt_current_root: String = ""
var _lt_current_files: Dictionary = {}
var _lt_archive_samples: Dictionary = {}
var _lt_bound_level_id: int = 0

func _lt_defaults() -> void:
	_profile_id = "challenge"
	_side = -1
	var catalogue: CinderEquipment = EquipmentScript.new()
	catalogue.reset_starter()
	_kit = catalogue.snapshot()
	_stats = catalogue.resolved_stats()
	_test_root = "user://test-a3-l1-arrangement-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_canonical_bytes = FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH)

func _lt_read_exact(path: String) -> Dictionary:
	var parsed: Dictionary = ExactJson.parse(FileAccess.get_file_as_string(path))
	if not _expect(parsed.get("accepted") == true and parsed.get("value") is Dictionary,"sealed exact original dictionary decodes: "+path): return {}
	return parsed.value

func _lt_verify_original() -> bool:
	var path: String = FIXTURE_ROOT.path_join("manifest.json")
	if not _expect(LT_LEGACY_MANIFEST_SHA256.length() == 64 and FileAccess.get_sha256(path) == LT_LEGACY_MANIFEST_SHA256,"ROOT-reviewed successful ORIGINAL manifest hash is mandatory"): return false
	_lt_manifest = _lt_read_exact(path)
	if not _expect(_lt_manifest.get("kind") == "a3-l1-original-challenge-arrangement-legacy-1" and _lt_manifest.get("files") is Dictionary and _lt_manifest.get("samples") is Dictionary and _lt_manifest.samples.has("entrance") and _lt_manifest.samples.has("first-stalker-held") and _lt_manifest.get("source_pins",{}).get(RuntimePath) == ORIGINAL_RUNTIME_SHA256,"authentic manifest binds actual old writer and both original samples"): return false
	for relative: Variant in _lt_manifest.files:
		if not _expect(relative is String and not relative.is_absolute_path() and not relative.contains("..") and not relative.contains("://"),"sealed original relative path is bounded"): return false
		var row: Variant = _lt_manifest.files[relative]
		var file_path: String = FIXTURE_ROOT.path_join(relative)
		if not _expect(row is Dictionary and FileAccess.get_sha256(file_path) == row.get("sha256") and FileAccess.get_file_as_bytes(file_path).size() == row.get("bytes"),"all sealed original fixture bytes remain exact: "+relative): return false
	return true

func _lt_run_legacy() -> bool:
	_lt_defaults()
	if not _lt_verify_original(): return false
	_producer_raw = _lt_read_exact(FIXTURE_ROOT.path_join("registry.native.json"))
	var registry: CinderCampaignRegistry = ProductionRegistry.new(_producer_raw)
	_prefix.assign(registry.main_route().slice(0,10))
	if not _expect(registry.last_error.is_empty() and _prefix.size() == 10 and _prefix[-1] == "A2-L5" and registry.entry("A3-L1").scene_path == FullPath,"literal old fixture registry retains actual L1 MAIN and disclosed predecessor prefix10",registry.last_error): return false
	for sample: String in ["entrance","first-stalker-held"]:
		var unit: Dictionary = _lt_read_exact(FIXTURE_ROOT.path_join(sample+"/unit.native.json"))
		var session: Dictionary = _lt_read_exact(FIXTURE_ROOT.path_join(sample+"/session.native.json"))
		var checkpoint: Dictionary = _lt_read_exact(FIXTURE_ROOT.path_join(sample+"/checkpoint.native.json"))
		if not _expect(not unit.is_empty() and _exact(session.story.snapshot,unit) and _exact(session.story.checkpoint,checkpoint) and session.side_attempt == null and session.completed_main == _prefix,"sealed originals carry actual MAIN current/protected units: "+sample): return false
		if not _lt_stage_original(sample): return false
		_watch_restore = true
		_restore_events.clear()
		if not node_added.is_connected(_observe_candidate): node_added.connect(_observe_candidate)
		if not await _lt_new_shell(session): return false
		if not _lt_set_preference("assisted",{}): return false
		_shell.menu.continue_story_requested.emit() # Actual MAIN Continue, never Resume Side.
		if not await _lt_wait_exact(unit,{}): return false
		if not _lt_installed(unit,true) or not await _lt_quiet(unit,session): return false
		if sample == "first-stalker-held":
			var receipt: Dictionary = _lt_read_exact(FIXTURE_ROOT.path_join(sample+"/receipt.json"))
			if not _expect(_exact(_lt_warning_core(_producer_warning_receipt()),_lt_warning_core(receipt.held_warning)),"legacy fresh recipient retains genuine moved C50 warning/lease/deadlines"): return false
		if not await _lt_retry_exact(checkpoint,session,true): return false
		if not await _lt_close_shell("literal legacy "+sample): return false
	return _expect(_lt_verify_original(),"literal old format2 files remain unchanged after fresh Continue/latest MAIN Retry")

func _lt_stage_original(sample: String) -> bool:
	# Only isolated disposable user files are replaced, with no active Shell.
	if not _expect(not is_instance_valid(_shell),"raw original Store staging occurs with no live recipient"): return false
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_root)) == OK,"isolated original Store folder opens"): return false
	for name: String in ["campaign.json","campaign.json.bak","preferences.json","preferences.json.bak","settings.json","settings.json.bak"]:
		if FileAccess.file_exists(_test_root+name):
			if not _expect(DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_root+name)) == OK,"remove only prior isolated disposable file: "+name): return false
	for pair: Array in [["campaign.store.json","campaign.json"],["preferences.store.json","preferences.json"],["campaign.store.json.bak","campaign.json.bak"]]:
		var source: String = FIXTURE_ROOT.path_join(sample+"/"+pair[0])
		if not FileAccess.file_exists(source):
			if pair[0].ends_with(".bak"): continue
			return _expect(false,"required original raw Store is missing: "+source)
		if not _lt_copy_checked(source,_test_root+pair[1]): return false
	return true

func _lt_new_shell(expected_session: Dictionary) -> bool:
	_shell = ProductionShell.new()
	_game = _shell
	if not _expect(_shell.configure_runtime(_producer_raw,_test_root+"campaign.json",_test_root+"settings.json",_test_root+"preferences.json"),"new actual MAIN Shell configures isolated original/current Store"): return false
	root.add_child(_shell)
	if not await _producer_settle("title",false): return false
	return _expect(_exact(_shell.attempts.state(),expected_session) and _shell.attempts.active_kind() == "story" and not is_instance_valid(_shell.active_level),"public paused startup loads complete exact MAIN session without installed donor")

func _lt_set_preference(profile: String, expected_unit: Dictionary) -> bool:
	var before: Dictionary = _shell.attempts.state()
	_shell.menu.show_settings()
	var selector := _shell.menu.find_child("DifficultySelector",true,false) as OptionButton
	if not _expect(is_instance_valid(selector),"actual public difficulty selector exists"): return false
	var index: int = -1
	for i: int in range(selector.item_count):
		if selector.get_item_metadata(i) == profile: index = i
	if not _expect(index >= 0,"canonical future preference exists: "+profile): return false
	selector.select(index)
	selector.item_selected.emit(index)
	var store: CinderSaveStore = ProductionStore.new(_test_root+"preferences.json")
	if not _expect(_shell.get_difficulty_preference() == profile and _exact(store.read_payload(),{"schema_version":1,"profile_id":profile}) and _exact(_shell.attempts.state(),before),"public preference only changes future encounters, retaining exact current MAIN history"): return false
	return expected_unit.is_empty() or _expect(_exact(_shell.capture_campaign_snapshot(),expected_unit),"public future preference preserves whole native current unit")

func _lt_wait_exact(unit: Dictionary, previous_ids: Dictionary) -> bool:
	for _frame: int in range(120):
		await process_frame
		if not _expect(is_instance_valid(_shell) and _shell.campaign_error.is_empty(),"public MAIN restore has no refusal",_shell.campaign_error if is_instance_valid(_shell) else "Shell freed"): return false
		if not paused or not is_instance_valid(_shell.active_level) or not is_instance_valid(_shell.player) or _shell.menu.page_name() != "resume": continue
		# The previous Resume menu may survive while Retry is queued. Require
		# the real stage/world replacement as well as the exact target packet.
		if not previous_ids.is_empty() and _shell.world.get_instance_id() == previous_ids.world: continue
		if not _exact(_shell.capture_campaign_snapshot(),unit): continue
		await process_frame
		return _expect(paused and _shell.campaign_error.is_empty() and _exact(_shell.capture_campaign_snapshot(),unit),"public install exact target remains paused after normal deferred/UI boundary")
	return _expect(false,"public MAIN replacement exceeds bounded120 process observations",str({"menu":_shell.menu.page_name(),"error":_shell.campaign_error,"target_checkpoint":unit.level.progress.checkpoint_id}))

func _lt_installed(unit: Dictionary, legacy: bool) -> bool:
	_hero = _shell.player
	_level = _shell.active_level
	var error: String = ""
	if _lt_bound_level_id != _level.get_instance_id():
		error = _bind_runtime()
		if error.is_empty(): _lt_bound_level_id = _level.get_instance_id()
	if not _expect(error.is_empty(),"actual installed recipient joins all five C50s/native Scheduler/profile/floor",error): return false
	_hp_before = _hero.hp
	_topology = _world_topology()
	_route_deadline = _scheduler.get_clock()+70.0
	var local: Dictionary = unit.level.local
	var expected_keys: Array = OLD_KEYS if legacy else LT_NEW_KEYS
	if not _expect(Codec.keys_error(local,expected_keys).is_empty() and local.api_revision == ("act3-twin-suns-level-1" if legacy else "act3-twin-suns-level-2") and local.schema_version == (1 if legacy else 2) and unit.level.local_snapshot_version == 5 and local.scheduler.world_revision == 1 and local.scheduler.profile.id == "challenge" and unit.shell.difficulty_at_entry == "challenge","installed native unit retains literal old/new API and saved Challenge independent of future preference"): return false
	var chosen: Dictionary = LT_Runtime.arrangement_constructor(local)
	var starts: Dictionary = OLD_ORIGINS if legacy else LT_CHALLENGE_STARTS
	if not _expect(chosen.get("error") == "" and chosen.legacy == legacy and _exact(chosen.starts,starts) and _exact(_level.call("selected_source_positions"),starts),"once-configured actual native recipient has the exact retained five-source origin map",str(chosen)): return false
	if not legacy and not _expect(local.arrangement.recipe_id == "A3-L1/challenge-crossing-depth@v2" and local.arrangement.profile == "challenge","current descriptor retains the actual changed crossing-depth recipe"): return false
	for id: String in SourceIds:
		var actor: Dictionary = local.sources[id]
		if not _expect(_exact((_sources[id] as CinderAct3SunboundStalker).snapshot_state(),actor) and actor.stable_id == id and actor.resolved_role.difficulty_profile == "challenge","all native current poses/history/roles recapture exactly: "+id): return false
		# Future pocket guards are recipe-relative. Entered actors are NOT
		# forced home: saved movement/death/sample bindings remain authoritative.
		if int(LT_Runtime.SOURCE_POCKETS[id]) >= local.route.entries.size():
			if not _expect(Codec.read_vector3(actor.position) == starts[id] and actor.cycle == 0 and actor.reservation_id.is_empty(),"only dormant future C50 stays at retained selected origin: "+id): return false
	var union: Dictionary = _level.call("camera_framing_union","",[],true)
	var points: Array = (union.get("points",[]) as Array).duplicate()
	points.append_array(_shell.player_camera_framing_points_for(_hero,_shell.camera))
	var optics: String = String(union.get("error",""))
	if optics.is_empty(): optics = _shell.camera_framing_error_for_context(points,_hero,_shell.camera,_shell.hud)
	return _expect(_shell.camera == _hero.get_viewport().get_camera_3d() and _shell.camera.get_world_3d() == _hero.get_world_3d() and optics.is_empty() and _exact(_shell.capture_campaign_snapshot(),unit),"actual installed Camera/HUD/held union and full native recapture remain exact",optics)

func _lt_ids() -> Dictionary:
	var ids: Dictionary = {"world":_shell.world.get_instance_id(),"level":_shell.active_level.get_instance_id(),"hero":_shell.player.get_instance_id(),"scheduler":(_shell.active_level.get("threat_scheduler") as Node).get_instance_id(),"camera":_shell.camera.get_instance_id(),"floor":((_shell.active_level.get("scenery") as Node).get("floor_body") as Node).get_instance_id()}
	for id: String in SourceIds: ids[id] = ((_shell.active_level.get("sources") as Dictionary)[id] as Node).get_instance_id()
	return ids

func _lt_retry_exact(checkpoint: Dictionary, before_session: Dictionary, legacy: bool) -> bool:
	var old_ids: Dictionary = _lt_ids()
	var old_refs: Array[WeakRef] = []
	var old_container: Node = _shell.world.get_parent().get_parent()
	if not _expect(old_container.get_parent() == _shell and old_container is SubViewportContainer,"Retry custody captures the actual complete old viewport container"): return false
	_lt_collect(old_container,old_refs)
	_watch_restore = false # Public donor cancellation during disposal is legitimate.
	_restore_events.clear()
	_shell.request_retry()
	_watch_restore = true
	if not await _lt_wait_exact(checkpoint,old_ids): return false
	for key: String in old_ids:
		if not _expect(_lt_ids()[key] != old_ids[key],"Retry creates a genuine distinct native recipient: "+key): return false
	if not await _lt_released(old_refs,"Retry old world/subtree") or not _lt_installed(checkpoint,legacy): return false
	var expected_session: Dictionary = before_session.duplicate(true)
	expected_session.story.snapshot = checkpoint.duplicate(true)
	if not _expect(_exact(_shell.attempts.state(),expected_session) and _exact(_shell.attempts.state().story.checkpoint,checkpoint) and _shell.attempts.active_kind() == "story","latest MAIN entry checkpoint replaces only current snapshot, preserving complete session/progression"): return false
	if not await _lt_quiet(checkpoint,expected_session): return false
	return _lt_disk(expected_session)

func _lt_quiet(unit: Dictionary, session: Dictionary) -> bool:
	if not _expect(_restore_events.is_empty(),"fresh construction/quiet restore emits no Hero/source/progression gameplay callbacks",str(_restore_events)): return false
	var before: Dictionary = {"unit":_shell.capture_campaign_snapshot(),"session":_shell.attempts.state(),"events":_events.duplicate(true),"restoration_events":_restore_events.duplicate(),"input":_shell.get_input_observation_state(),"ids":_lt_ids()}
	for _frame: int in range(3): await process_frame
	return _expect(paused and _exact(before.unit,unit) and _exact(before.session,session) and _exact(_shell.capture_campaign_snapshot(),unit) and _exact(_shell.attempts.state(),session) and _exact(_events,before.events) and _exact(_restore_events,before.restoration_events) and _exact(_shell.get_input_observation_state(),before.input) and _exact(_lt_ids(),before.ids),"paused whole MAIN native unit/input/clocks/identities/events/session stay exact across ordinary process boundaries")

func _lt_disk(session: Dictionary) -> bool:
	var reader: CinderSaveStore = ProductionStore.new(_test_root+"campaign.json")
	var actual: Dictionary = reader.read_payload()
	return _expect(reader.last_error.is_empty() and not reader.loaded_backup and _exact(actual,session),"independent actual primary format2 Store equals complete MAIN session",reader.last_error)

func _lt_warning_core(receipt: Dictionary) -> Dictionary:
	var core: Dictionary = receipt.duplicate(true)
	core.erase("actual_source_instance_id_decimal_text") # Fresh actual native owner must differ.
	return core

func _lt_collect(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _lt_collect(child,refs)

func _lt_released(refs: Array[WeakRef], label: String) -> bool:
	for _frame: int in range(120):
		var freed: bool = true
		for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
		if freed: return _expect(true,label+": complete native old subtree is freed")
		await process_frame
	return _expect(false,label+": retained old native subtree remains")

func _lt_close_shell(label: String) -> bool:
	if not is_instance_valid(_shell): return true
	_watch_restore = false
	var refs: Array[WeakRef] = []
	_lt_collect(_shell,refs)
	if is_instance_valid(_shell.active_level) and _shell.active_level.is_inside_tree():
		var scheduler := _shell.active_level.get("threat_scheduler") as CinderThreatScheduler
		_shell.active_level.exit_level()
		for id: String in SourceIds:
			if not _expect(scheduler.source_control_state((_shell.active_level.get("sources") as Dictionary)[id]).get("reservations",[]).is_empty(),"supported inside-tree exit releases actual owner: "+id): return false
	_shell.queue_free()
	_shell = null
	_game = null
	_hero = null
	_level = null
	_scheduler = null
	_sources.clear()
	_lt_bound_level_id = 0
	var released: bool = await _lt_released(refs,label)
	return released and _expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),label+": no native enemy/cue remnant")

func _lt_copy_checked(source: String, target: String) -> bool:
	var sha: String = FileAccess.get_sha256(source)
	return _expect(sha.length() == 64 and not FileAccess.file_exists(target) and DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(target)) == OK and FileAccess.get_sha256(source) == sha and FileAccess.get_sha256(target) == sha,"raw Store/native source bytes copy unchanged: "+source)

func _lt_run_current_persistence() -> bool:
	_lt_defaults()
	var parsed: Variant = JSON.parse_string(_canonical_bytes)
	if not _expect(parsed is Dictionary,"current canonical registry is readable"): return false
	_producer_raw = parsed.duplicate(true)
	for row: Dictionary in _producer_raw.levels:
		if row.id == "A2-L5": row.scene_path = PredecessorFixturePath
	var registry: CinderCampaignRegistry = ProductionRegistry.new(_producer_raw)
	_prefix.assign(registry.main_route().slice(0,10))
	if not _expect(registry.last_error.is_empty() and _prefix.size() == 10 and _prefix[-1] == "A2-L5" and registry.entry("A3-L1").scene_path == FullPath,"new current writer still uses actual MAIN L1 and TEST predecessor prefix10 only",registry.last_error): return false
	var predecessor: Dictionary = await _producer_predecessor()
	if predecessor.is_empty() or not _producer_capture_pins(): return false
	var model: CinderCampaignAttempts = AttemptsModel.new(registry)
	_producer_seed = model.state()
	_producer_seed.completed_main = _prefix.duplicate()
	_producer_seed.story = {"kind":"story","level_id":"A2-L5","snapshot":predecessor.duplicate(true),"checkpoint":predecessor.duplicate(true)}
	var store: CinderSaveStore = ProductionStore.new(_test_root+"campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(_producer_seed).is_empty() and store.write_payload(_producer_seed),"current TEST seed contains only genuine predecessor native writers",model.last_error+"; "+store.last_error): return false
	if not await _lt_new_shell(_producer_seed) or not _lt_set_preference("challenge",{}): return false
	_shell.menu.continue_story_requested.emit()
	if not await _producer_settle("resume",true,"A2-L5"): return false
	if not _expect(_exact(_shell.capture_campaign_snapshot(),predecessor) and _shell.active_level.request_completion("test-only-predecessor-clear"),"actual predecessor public Continue/completion remains unchanged"): return false
	if not await _producer_settle("resume",true,"A2-L5"): return false
	if not _expect(_shell.active_level.is_completed() and _shell.active_level.request_contact_exit("test-only-fresh-challenge-entry",_shell.player),"real TEST predecessor contact starts genuinely fresh current Challenge L1"): return false
	if not await _producer_settle("resume",true,"A3-L1"): return false
	_producer_entrance = _shell.capture_campaign_snapshot()
	if not _lt_installed(_producer_entrance,false): return false
	_producer_origins.clear()
	for id: String in SourceIds: _producer_origins[id] = Codec.vector3((_sources[id] as Node3D).global_position)
	if not _expect(_producer_entrance.player.world_actions.clock_s == 0.0 and _producer_entrance.level.local.scheduler.clock_s == 0.0 and _producer_entrance.level.local.route.entries.is_empty() and _producer_entrance.level.local.route.deaths.is_empty(),"new recipe is genuinely initial; no crossing entitlement or gameplay is fabricated"): return false
	_lt_current_root = "res://captures/act3/twin-suns-arrangement/current-held-%d-%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_lt_current_root)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_lt_current_root)) == OK,"new current provenance directory never overwrites originals"): return false
	if not _lt_write("registry.native.json",_producer_raw) or not _lt_write("start-session.native.json",_producer_seed) or not _lt_write("source-pins.json",{"source_pins":_producer_pins,"resource_uid_text":_producer_uids}) or not _lt_archive_current("entrance",_producer_entrance,{}): return false
	_shell.resume_lab()
	if not _expect(not paused,"public resume starts genuine current first-entry approach"): return false
	var error: String = await _travel_entry(0)
	if not _expect(error.is_empty(),"current first-entry route retains original native dash/proof/HP controls",error): return false
	var held: Dictionary = {}
	for _tick: int in range(_frame_limit(WarningBudgetS)):
		if _sources[SourceIds[0]].state().phase == "warning":
			_shell.request_pause()
			if not await _producer_settle("pause",true,"A3-L1"): return false
			held = _shell.capture_campaign_snapshot()
			break
		error = await _tick_safe()
		if not error.is_empty(): break
	var receipt: Dictionary = _producer_warning_receipt()
	if not _expect(error.is_empty() and not held.is_empty() and not receipt.is_empty(),"actual new current held first C50 warning is observed, never synthesized",error): return false
	if not _lt_installed(held,false) or not _lt_archive_current("first-stalker-held",held,receipt): return false
	var saved: Dictionary = _shell.attempts.state()
	var protected_checkpoint: Dictionary = saved.story.checkpoint.duplicate(true)
	if not _expect(protected_checkpoint.level.progress.checkpoint_id == CheckpointIds[0] and protected_checkpoint.level.local.route.entries.size() == 1 and saved.completed_main == _prefix and saved.side_attempt == null,"actual new current protected checkpoint is CP1 MAIN, not optional entrance"): return false
	if not _lt_write("manifest.json",{"schema_version":1,"kind":"a3-l1-current-crossing-depth-arrangement-2","test_only":true,"files":_lt_current_files.duplicate(true),"source_pins":_producer_pins,"resource_uid_text":_producer_uids,"samples":_lt_archive_samples,"observed_entrance_origins":_producer_origins,"scope":"Authentic fresh Challenge MAIN entrance/current first warning and latest first-entry checkpoint, no earned crossing/deaths/completion. Raw native Store copies before disposal; later opposite-preference Continue/Retry governed by actual runner."}): return false
	var old_ids: Dictionary = _lt_ids()
	if not _lt_set_preference("assisted",held) or not await _lt_close_shell("new current warning donor"): return false
	_watch_restore = true
	_restore_events.clear()
	if not node_added.is_connected(_observe_candidate): node_added.connect(_observe_candidate)
	if not await _lt_new_shell(saved): return false
	if not _expect(_shell.get_difficulty_preference() == "assisted","new actual disk Shell retains opposite future preference"): return false
	_shell.menu.continue_story_requested.emit()
	if not await _lt_wait_exact(held,{}): return false
	for key: String in old_ids:
		if not _expect(_lt_ids()[key] != old_ids[key],"fresh disk Continue replaces actual donor identity: "+key): return false
	if not _lt_installed(held,false) or not await _lt_quiet(held,saved) or not _expect(_exact(_lt_warning_core(_producer_warning_receipt()),_lt_warning_core(receipt)),"new current disk Continue retains original actual moved C50 warning/lease/deadlines"): return false
	if not await _lt_retry_exact(protected_checkpoint,saved,false): return false
	return await _lt_close_shell("new current latest checkpoint Retry")

func _lt_archive_current(label: String, unit: Dictionary, receipt: Dictionary) -> bool:
	var session: Dictionary = _shell.attempts.state()
	if not _expect(_exact(session.story.snapshot,unit) and session.side_attempt == null and session.completed_main == _prefix,"archive actual current MAIN unit/session joins: "+label) or not _lt_disk(session): return false
	var folder: String = _lt_current_root.path_join(label)
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"current native archive sample folder opens"): return false
	if not _lt_write(label+"/unit.native.json",unit) or not _lt_write(label+"/session.native.json",session) or not _lt_write(label+"/checkpoint.native.json",session.story.checkpoint) or not _lt_write(label+"/receipt.json",{"schema_version":1,"test_only":true,"sample":label,"observed_entrance_origins":_producer_origins,"held_warning":receipt}): return false
	for pair: Array in [["campaign.json","campaign.store.json"],["preferences.json","preferences.store.json"],["campaign.json.bak","campaign.store.json.bak"]]:
		var source: String = _test_root+pair[0]
		if not FileAccess.file_exists(source):
			if pair[0].ends_with(".bak"): continue
			return _expect(false,"required current native Store is missing: "+source)
		var relative: String = label+"/"+pair[1]
		var target: String = _lt_current_root.path_join(relative)
		if not _lt_copy_checked(source,target): return false
		_lt_current_files[relative] = {"sha256":FileAccess.get_sha256(target),"bytes":FileAccess.get_file_as_bytes(target).size(),"raw_store_copy":true,"original_user_path":source}
	_lt_archive_samples[label] = {"unit":label+"/unit.native.json","session":label+"/session.native.json","checkpoint":label+"/checkpoint.native.json","receipt":label+"/receipt.json"}
	return _expect(_exact(_shell.capture_campaign_snapshot(),unit) and _exact(_shell.attempts.state(),session),"current exact archive writes never mutate native gameplay/session: "+label)

func _lt_write(relative: String, value: Dictionary) -> bool:
	var wire: String = ExactJson.stringify(value)
	var target: String = _lt_current_root.path_join(relative)
	if not _expect(not wire.is_empty() and not FileAccess.file_exists(target),"new finite ExactJSON current archive only: "+relative): return false
	var file := FileAccess.open(target,FileAccess.WRITE)
	if not _expect(file != null,"current archive opens: "+relative): return false
	file.store_string(wire+"\n")
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if not _expect(error == OK and FileAccess.get_file_as_string(target) == wire+"\n","current archive exact bytes persist: "+relative): return false
	_lt_current_files[relative] = {"sha256":FileAccess.get_sha256(target),"bytes":FileAccess.get_file_as_bytes(target).size(),"exact_wire_sha256":wire.sha256_text()}
	return true

func _lt_run_pure() -> bool:
	_lt_defaults()
	if not _lt_verify_original(): return false
	var entrance: Dictionary = _lt_read_exact(FIXTURE_ROOT.path_join("entrance/unit.native.json"))
	var held: Dictionary = _lt_read_exact(FIXTURE_ROOT.path_join("first-stalker-held/unit.native.json"))
	var selector: CinderEncounterArrangement = LT_Arrangement.new(LT_Runtime.arrangement_definition())
	for profile: String in ["assisted","standard","challenge"]:
		var descriptor: Dictionary = selector.select_fresh(profile)
		var before: PackedByteArray = var_to_bytes(descriptor)
		var selected: Dictionary = LT_Runtime.arrangement_layout(descriptor)
		if not _expect(selected.get("error") == "" and var_to_bytes(descriptor) == before and _exact(selected.starts,LT_CHALLENGE_STARTS if profile == "challenge" else OLD_ORIGINS),"pure complete depth-only map/profile selection is immutable: "+profile): return false
		for id: String in SourceIds:
			if not _expect((selected.starts[id] as Vector3).x == (OLD_ORIGINS[id] as Vector3).x and (selected.starts[id] as Vector3).y == (OLD_ORIGINS[id] as Vector3).y,"depth recipe retains recipient X/nativeY: "+id): return false
	var locals: Array[Dictionary] = [entrance.level.local,held.level.local]
	for local: Dictionary in locals:
		var before: PackedByteArray = var_to_bytes(local)
		var receipt: Dictionary = LT_Runtime.arrangement_constructor(local)
		if not _expect(receipt.get("error") == "" and receipt.legacy and _exact(receipt.starts,OLD_ORIGINS) and var_to_bytes(local) == before,"authentic literal old Challenge constructor accepts original unit without mutation"): return false
	var first: Dictionary = held.level.local.sources[SourceIds[0]]
	if not _expect(Codec.read_vector3(first.position) != OLD_ORIGINS[SourceIds[0]],"positive entered-moved-pose control uses actual producer movement, never a fabricated displacement"): return false
	var represented: Dictionary = entrance.level.local.duplicate(true)
	var changed_numeric_representation: bool = false
	for key: String in represented.scheduler.profile:
		var value: Variant = represented.scheduler.profile[key]
		if value is int:
			represented.scheduler.profile[key] = float(value)
			changed_numeric_representation = true
			break
		elif value is float and value == floorf(value):
			represented.scheduler.profile[key] = int(value)
			changed_numeric_representation = true
			break
	if not _expect(changed_numeric_representation and LT_Runtime.arrangement_constructor(represented).get("error") == "","pure legacy profile int/float representation matches native schema1 semantics; not fixture history"): return false
	var negatives: Array[Dictionary] = []
	var bad: Dictionary = entrance.level.local.duplicate(true)
	bad["arrangement"] = selector.select_fresh("challenge")
	negatives.append({"label":"legacy extra descriptor","value":bad})
	bad = entrance.level.local.duplicate(true); bad.api_revision = "act3-twin-suns-level-2"; negatives.append({"label":"new API with old schema/keys","value":bad})
	bad = entrance.level.local.duplicate(true); bad.schema_version = 2; negatives.append({"label":"old API with new schema","value":bad})
	bad = entrance.level.local.duplicate(true); bad.erase("route"); negatives.append({"label":"missing route","value":bad})
	bad = entrance.level.local.duplicate(true); bad.scheduler.profile.id = "unpublished"; negatives.append({"label":"unknown profile","value":bad})
	bad = entrance.level.local.duplicate(true); bad.scheduler.profile["extra"] = true; negatives.append({"label":"noncanonical profile","value":bad})
	for axis: int in range(3):
		bad = entrance.level.local.duplicate(true)
		bad.sources["l1-crossing-west"].position[axis] += 0.25
		negatives.append({"label":"wrong dormant selected origin axis"+str(axis),"value":bad})
	bad = held.level.local.duplicate(true); bad.sources["l1-departure-stalker"].resolved_role.difficulty_profile = "standard"; negatives.append({"label":"native role/profile mismatch","value":bad})
	for row: Dictionary in negatives:
		var bytes_before: PackedByteArray = var_to_bytes(row.value)
		if not _expect(not String(LT_Runtime.arrangement_constructor(row.value).get("error","")).is_empty() and var_to_bytes(row.value) == bytes_before,"pure malformed local rejects without mutation: "+row.label): return false
	var descriptor: Dictionary = selector.select_fresh("challenge")
	var bad_descriptors: Array[Dictionary] = []
	bad = descriptor.duplicate(true); bad.profile = "standard"; bad_descriptors.append(bad)
	bad = descriptor.duplicate(true); bad.recipe_id = "A3-L1/unknown"; bad_descriptors.append(bad)
	bad = descriptor.duplicate(true); bad.order[0] = bad.order[1]; bad_descriptors.append(bad)
	bad = descriptor.duplicate(true)
	var swapped: Variant = bad.order[0]
	bad.order[0] = bad.order[4]
	bad.order[4] = swapped
	bad_descriptors.append(bad)
	bad = descriptor.duplicate(true); bad["extra"] = true; bad_descriptors.append(bad)
	for malformed: Dictionary in bad_descriptors:
		var before: PackedByteArray = var_to_bytes(malformed)
		if not _expect(not String(LT_Runtime.arrangement_layout(malformed).get("error","")).is_empty() and var_to_bytes(malformed) == before,"pure closed recipe/profile/permutation rejects with no native mutation"): return false
	return true


## PRIVATE SOURCE FRAGMENT — NOT INSTALLED, PARSED OR EXECUTED.
## Append to the ONE twin_suns_arrangement_smoke.gd extending
## twin_suns_production_transition_smoke.gd. No extends/_run/_finish override.
##
## Required dispatcher edits by composer:
## 1. FIRST branch of existing producer _tick_safe():
##       if _lc_running: return await _lc_tick_safe()
##    Keep its producer body unchanged for all other selectors.
## 2. Selector: await _lc_run("--crossing-compare").
##    Runs canonical baseline, changed baseline, then ONE changed combined
##    WEAPON-03/CLOTH-P2/CLOTH-S2 opportunity sample. No weak/all-kit matrix.
## 3. Common fatal/watchdog/final cleanup: await _lc_dispose() if _lc_running;
##    never quit while its Main/observer/cache remains live.
## 4. --crossing-portrait is a later integration point, deliberately refuses
##    execution unless a reviewed paused portrait_writer Callable is supplied.
##
## Reuses inherited actual native _pending/_proof_error/_at_time/_dash/_hold/
## _primary_opening_error/_fixed_record/_floor_hit/_world_topology helpers.
## Does NOT call _clear_pocket, _primary (which depletes shells), _prepare,
## _bind_runtime, _next_warning (which may route-rejoin), or any save helper.
## Every new declared constant/member/helper has LC or _lc prefix.

const LC_Runtime = preload("res://scripts/acts/act3/twin_suns_level.gd")
const LC_CROSS_IDS: Array[String] = ["l1-crossing-west", "l1-crossing-east"]
const LC_START: Vector3 = Vector3(0, 0.1, -10)
const LC_NATIVE_LIMIT: int = 1800
const LC_CASE_SECONDS: float = 30.0
const LC_SAVE_LIMIT: String = "TEST crossing component has no canonical route/save authority"

class LC_AfterMain extends Node:
	signal observed(boundary: String)
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_priority = 1000
	func _process(_delta: float) -> void:
		if waiting:
			waiting = false
			observed.emit("post_main_process")

class LC_CrossingLab extends LC_Runtime:
	## These authored TEST constructor choices are set BEFORE packing/entry.
	## They are not a production progress prefix or a saved-world seed.
	@export var lc_changed: bool = true
	var lc_native_deaths: Array[String] = []

	func _on_enter_level() -> void:
		_active = true
		var descriptor: Dictionary
		var selector := Arrangement.new(arrangement_definition())
		if lc_changed:
			descriptor = selector.select_fresh("challenge")
		else:
			descriptor = {
				"schema_version": 1, "profile": "challenge",
				"recipe_id": LEGACY_RECIPE_IDS.challenge,
				"order": SOURCE_IDS.duplicate()
			}
		_configuration_error = selector.last_error if descriptor.is_empty() else _configure_sources(descriptor, false)
		scenery.call("follow_landmarks", hero.global_position)
		_update_presentation()

	func _advance_entry() -> bool:
		return false

	func _all_cleared() -> bool:
		return false

	func _on_source_died(_where: Vector3, id: String) -> void:
		# Genuine native observation only, outside the canonical route dictionaries.
		if sources.has(id) and sources[id].dead and sources[id].hp == 0.0:
			lc_native_deaths.append(id)

	func _update_presentation(silent: bool = false) -> void:
		super._update_presentation(silent)
		for id: String in SOURCE_IDS:
			if is_instance_valid(sources.get(id)):
				sources[id].set_physics_process(int(SOURCE_POCKETS[id]) == 2 and not sources[id].dead)
		objective_text = "TEST CROSSING DEPTH COMPARISON\nREAL STALKER LANDING; ONE ORDINARY PRIMARY"

	func snapshot_state() -> Dictionary:
		last_snapshot_error = LC_SAVE_LIMIT
		return {}
	func snapshot_state_for_presentation(_camera: Camera3D, _hud: GameHUD) -> Dictionary:
		last_snapshot_error = LC_SAVE_LIMIT
		return {}
	func snapshot_error(_snapshot: Dictionary) -> String:
		return LC_SAVE_LIMIT
	func snapshot_error_with_player(_snapshot: Dictionary, _player: Dictionary) -> String:
		return LC_SAVE_LIMIT
	func restore_state(_snapshot: Dictionary) -> bool:
		last_snapshot_error = LC_SAVE_LIMIT
		return false
	func _local_snapshot_error(_local: Dictionary) -> String:
		return LC_SAVE_LIMIT
	func _local_snapshot_error_with_player(_local: Dictionary, _player: Dictionary) -> String:
		return LC_SAVE_LIMIT
	func _on_enter_restore_candidate(_local: Dictionary, _player: Dictionary) -> String:
		return LC_SAVE_LIMIT

var _lc_running: bool = false
var _lc_stopping: bool = false
var _lc_ticks: int = 0
var _lc_scene: PackedScene
var _lc_scene_path: String = ""
var _lc_after_main: LC_AfterMain
var _lc_connections: Array[Array] = []
var _lc_refs: Array[WeakRef] = []
var _lc_seen: Dictionary = {}
var _lc_start_hp: float = 0.0
var _lc_origins: Dictionary = {}
var _lc_hit: Dictionary = {}
var _lc_results: Array[Dictionary] = []
var _lc_declines: Dictionary = {}

func _lc_run(selector: String, portrait_writer: Callable = Callable()) -> bool:
	if not _expect(selector in ["--crossing-compare", "--crossing-portrait"], "one bounded TEST crossing selector", selector): return false
	if not _expect(LC_Runtime.ROUTE_API == "act3-twin-suns-level-2", "component waits for separately approved reader promotion"): return false
	if not _expect(not is_instance_valid(_game) and not is_instance_valid(_shell), "component starts without a producer or prior Main/Shell"): return false
	_lc_running = true
	_lc_results.clear()
	var cases: Array = [
		{"label":"canonical-baseline", "changed":false, "combined":false},
		{"label":"challenge-baseline", "changed":true, "combined":false},
		{"label":"challenge-short-slow", "changed":true, "combined":true}
	] if selector == "--crossing-compare" else [{"label":"challenge-portrait", "changed":true, "combined":false}]
	for choice: Dictionary in cases:
		var result: Dictionary = await _lc_case(choice, portrait_writer if selector == "--crossing-portrait" else Callable())
		var retired: String = await _lc_dispose()
		if not _expect(String(result.get("error", "Missing actual case result")).is_empty(), "actual crossing opportunity: " + choice.label, str(result)): _lc_running = false; return false
		if not _expect(retired.is_empty(), "normal crossing component retirement: " + choice.label, retired): _lc_running = false; return false
		_lc_results.append(result)
	if selector == "--crossing-compare":
		var original: Dictionary = _lc_results[0]
		var changed: Dictionary = _lc_results[1]
		# Compare PHYSICAL executed positions only, not source IDs, clocks,
		# metadata, warning order, serials, or the two authored home constants.
		var different: bool = original.executed_landings.size() != changed.executed_landings.size()
		if not different:
			for index: int in range(original.executed_landings.size()):
				if (original.executed_landings[index] as Vector3).distance_to(changed.executed_landings[index]) > PointTolerance: different = true
		different = different or (original.primary_world_origin as Vector3).distance_to(changed.primary_world_origin) > PointTolerance
		if not _expect(original.initial_position == LC_START and changed.initial_position == LC_START and original.kit == changed.kit and original.profile == changed.profile and original.initial_sun == changed.initial_sun and different,
			"same declared start/kit/profile/sun yields an observed useful executed landing/ordinary-return difference",
			str({"canonical":original, "challenge":changed, "observed_physical_difference":different})):
			_lc_running = false
			return false # Retain no-observed-difference; do not tune guards/stats.
	print("L1 CROSSING COMPONENT: ", _lc_results, "; TEST initial eligibility; no parent prefix/save/clear/contact/full-route or human-balance credit")
	_lc_running = false
	return true

func _lc_case(choice: Dictionary, portrait_writer: Callable) -> Dictionary:
	_lc_stopping = false
	_lc_ticks = 0
	_lc_hit.clear(); _lc_declines.clear()
	_lc_refs.clear(); _lc_seen.clear(); _lc_connections.clear()
	_warnings.clear(); _used_warnings.clear(); _records.clear(); _phases.clear(); _active_travel.clear()
	_actions.clear(); _events.clear(); _expected_hp.clear(); _checkpoints.clear(); _death_events.clear()
	_current.clear(); _source_id = ""; _group_ids.assign(LC_CROSS_IDS)
	_capture_portrait = false; _roundtrip_done = true; _fresh_partial_done = true
	_crossing_primary_deferred = false; _union_seen = false
	_route_deadline = LC_CASE_SECONDS; _group_deadline = LC_CASE_SECONDS
	_kit = {"jacket":"CLOTH-J0", "pants":"CLOTH-P0", "shoes":"CLOTH-S0", "weapon":"WEAPON-01"}
	if choice.combined:
		_kit.pants = "CLOTH-P2"; _kit.shoes = "CLOTH-S2"; _kit.weapon = "WEAPON-03"
	root.size = Vector2i(340,736); root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	paused = false
	_game = MainScene.instantiate()
	node_added.connect(_lc_watch_node)
	root.add_child(_game)
	_game.call("open_bench") # Synchronous enemy-free native lab; no physics seed.
	var lab_hero: CinderPlayer = _game.get("player") as CinderPlayer
	if lab_hero == null or not paused or not get_nodes_in_group("enemies").is_empty(): return {"error":"Actual paused enemy-free Main unavailable"}
	for slot: String in Slots:
		if not lab_hero.equip_item(String(_kit[slot])): return {"error":"Public initial equipment selection declined: "+slot}
	var packed: Dictionary = _lc_make_scene(choice.changed)
	if not String(packed.error).is_empty(): return packed
	_lc_scene = packed.scene; _lc_scene_path = packed.path
	if not _game.call("load_level_scene", _lc_scene_path): return {"error":"Actual public Main load declined: "+String(_game.get("level_load_error"))}
	_game.call("open_bench")
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _level is LC_CrossingLab or _hero == null or _hero == lab_hero: return {"error":"Fresh native component/Hero unavailable"}
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	_sources = (_level.get("sources") as Dictionary).duplicate()
	_floor = _level.get("scenery").get("floor_body") as StaticBody3D
	_motifs = _level.find_child("ScenicSuns",true,false) as Node3D
	_exit_cue = _level.get("exit_cue") as CinderInteractionCue
	_stats = _hero.equipment.resolved_stats()
	_lc_start_hp = _hero.hp; _hp_before = _hero.hp
	_lc_origins = _level.call("selected_source_positions")
	var actual: Dictionary = _level.call("state")
	if not paused or not _level.contract_error().is_empty() or _hero.global_position != LC_START or _hero.hp != _hero.max_hp or _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0 or int(_level.get("sun_state")) != 0 or not Codec.keys_error(_sources,SourceIds).is_empty():
		return {"error":"Actual declared constructor start/profile/clock/source contract differs"}
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var solid: CollisionShape3D = _floor.get_node("Solid") as CollisionShape3D
	if not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14,1,108) or bindings.owners != _sources or bindings.world_root != _level or bindings.floors["shelf-floor"].collision != solid or _level.hero != _hero or _level.shared_shell != _game or _scheduler.encounter_profile().id != "challenge":
		return {"error":"Actual native floor/owner/Hero/Challenge binding differs"}
	for id: String in SourceIds:
		var source: CinderAct3SunboundStalker = _sources[id] as CinderAct3SunboundStalker
		var origin: Vector3 = LC_Runtime.SOURCE_POSITIONS[id]
		if choice.changed and id == LC_CROSS_IDS[0]: origin.z = -17
		if choice.changed and id == LC_CROSS_IDS[1]: origin.z = -14
		if source == null or source.global_position != origin or _lc_origins[id] != origin or source.hp != 36.0 or source.dead or source.get_world_3d() != _hero.get_world_3d() or not source.is_in_group("enemies") or source.is_physics_processing() != LC_CROSS_IDS.has(id):
			return {"error":"Actual configured native source/home/eligibility differs: "+id}
		_expected_hp[id] = source.hp
		_lc_connect(source,"state_changed",_on_source_state.bind(id))
		_lc_connect(source,"hit_resolved",_on_contact.bind(id))
		_lc_connect(source,"died",_on_death.bind(id))
	_lc_connect(_hero,"world_action_executed",_on_action)
	_lc_connect(_hero,"fired",_lc_fired)
	_lc_connect(_level,"checkpoint_requested",_on_checkpoint)
	_lc_connect(_level,"completion_requested",_lc_completion)
	_lc_connect(_level,"contact_exit_requested",_lc_contact)
	if not _level.snapshot_state().is_empty() or _level.last_snapshot_error != LC_SAVE_LIMIT or not actual.entered.is_empty() or not actual.deaths.is_empty() or actual.completed:
		return {"error":"TEST component must refuse snapshots and retain no parent progress prefix"}
	_free_tick_barrier() # Producer initialization may already own an observer.
	_tick_barrier = PostActorPhysicsBarrier.new()
	_tick_barrier.name = "TEST_L1_CrossingPostActor"
	_tick_barrier.process_mode = Node.PROCESS_MODE_PAUSABLE
	_tick_barrier.process_physics_priority = 1000
	root.add_child(_tick_barrier)
	_lc_after_main = LC_AfterMain.new()
	_lc_after_main.name = "TEST_L1_CrossingAfterMain"
	root.add_child(_lc_after_main)
	_topology = _world_topology()
	_game.call("resume_lab")
	var error: String = ""
	for _ground_tick: int in range(8):
		if _hero.is_on_floor(): break
		error = await _lc_tick_safe()
		if not error.is_empty(): return {"error":error}
	if not _hero.is_on_floor(): return {"error":"Declared native Hero did not ground within the bounded actual entry ticks"}
	var first: Dictionary = await _lc_wait_warning()
	if first.is_empty(): return {"error":"No bounded usable actual crossing warning", "states":_lc_source_states()}
	if portrait_writer.is_valid():
		error = await _lc_post_main()
		if not error.is_empty(): return {"error":error}
		_game.call("open_bench")
		# Composer supplies a reviewed actual paused native draw/unchanged-state
		# reader; returning an empty/error result never earns visual credit.
		var visual: Dictionary = await portrait_writer.call(_game,_level,_hero,_scheduler,first)
		return {"error":String(visual.get("error","Missing actual portrait result")), "portrait":visual, "parent_route_or_save_credit":false}
	if choice.label == "challenge-portrait": return {"error":"Portrait selector UNEXECUTED until a reviewed paused draw adapter is supplied"}
	error = await _lc_follow_one(first)
	if not error.is_empty(): return {"error":error,"states":_lc_source_states()}
	error = await _lc_post_main()
	if not error.is_empty(): return {"error":error}
	var landings: Array[Vector3] = []
	for action: Dictionary in _actions:
		if action.kind == "dash": landings.append(action.landing)
	return {
		"error":"", "label":choice.label, "initial_position":LC_START,
		"initial_sun":0, "profile":_scheduler.encounter_profile().id,
		"kit":_kit.duplicate(true), "selected_origins":_lc_origins.duplicate(),
		"actual_warning_source":_lc_hit.source_id,
		"accepted_geometry":_lc_hit.geometry, "accepted_landing":_lc_hit.proof.landing,
		"accepted_attack_position":_lc_hit.proof.attack_position,
		"executed_landings":landings, "primary_world_origin":_lc_hit.action.world_origin,
		"actual_primary":_lc_hit.duplicate(true), "hero_hp":_hero.hp,
		"native_ticks":_lc_ticks, "all_sources":_lc_source_states(), "unleased_prospective_view_declines":_lc_declines.duplicate(true),
		"parent_route_or_save_credit":false
	}

func _lc_make_scene(changed: bool) -> Dictionary:
	var template: Node3D = load(FullPath).instantiate()
	var declared := LC_CrossingLab.new()
	declared.name = "TEST_L1_CrossingDepth"
	declared.level_id = "A3-L1"; declared.lc_changed = changed
	for child: Node in template.get_children():
		var copy: Node = child.duplicate()
		declared.add_child(copy)
		_lc_assign_owner(copy,declared)
	template.free()
	(declared.get_node(declared.spawn_path) as Marker3D).position = LC_START
	var scene := PackedScene.new()
	var error: Error = scene.pack(declared)
	declared.free()
	if error != OK: return {"error":"Declared native component packing failed"}
	var cache_path: String = "res://tests/acts/act3/__TEST_l1_crossing_%d_%d.tscn" % [OS.get_process_id(),Time.get_ticks_usec()]
	if FileAccess.file_exists(cache_path) or ResourceLoader.has_cached(cache_path): return {"error":"Unique TEST scene cache path already exists"}
	scene.take_over_path(cache_path)
	return {"error":"","scene":scene,"path":cache_path}

func _lc_assign_owner(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child: Node in node.get_children(): _lc_assign_owner(child,owner_node)

func _lc_wait_warning() -> Dictionary:
	var stop: float = minf(_route_deadline,_scheduler.get_clock()+WarningBudgetS)
	for _sample: int in range(_frame_limit(WarningBudgetS)):
		var warning: Dictionary = _pending() # Genuine newest current native union proof.
		if not warning.is_empty() and String(_proof_error(warning)).is_empty():
			var ready_s: float = float(warning.proof.path[0].end_s)
			if _scheduler.get_clock() < ready_s:
				_used_warnings[warning.record.id] = true
				return warning
		if _scheduler.get_clock() > stop: break
		var error: String = await _lc_tick_safe()
		if not error.is_empty():
			_expect(false,"bounded native crossing warning observation",error)
			return {}
	return {}

func _lc_follow_one(initial: Dictionary) -> String:
	var warning: Dictionary = initial
	for _episode: int in range(20):
		if warning.is_empty(): warning = await _lc_wait_warning()
		if warning.is_empty(): return "No bounded actual native union proof"
		_source_id = warning.id; _current = warning.record.duplicate(true)
		var error: String = _proof_error(warning)
		if not error.is_empty(): return error
		for segment: Dictionary in warning.proof.path:
			if segment.kind in ["escape_dash","positioning_dash"]:
				error = await _at_time(float(segment.start_s))
				if error.is_empty(): error = await _dash(segment)
			elif segment.kind == "ordinary_primary":
				error = await _lc_primary(segment,warning.proof)
				if error.is_empty(): return "" # Exactly one actual primary opportunity.
			else:
				error = await _hold(segment)
			if not error.is_empty(): break
		if error == Replan:
			warning = {}
			continue # New real warning from actual current Hero, no pose/history seed.
		if not error.is_empty(): return error
		return "Actual accepted witness had no ordinary primary"
	return "Bounded native crossing replans exhausted"

func _lc_primary(segment: Dictionary, proof: Dictionary) -> String:
	var error: String = await _at_time(float(proof.primary_time_s))
	if not error.is_empty(): return error
	error = _primary_opening_error(segment,proof)
	if not error.is_empty(): return error
	var source: CinderAct3SunboundStalker = _sources[_source_id]
	var before: Dictionary = _expected_hp.duplicate(true)
	var sequence: int = _last_sequence()
	var toward: Vector3 = _planar(source.global_position-_hero.global_position)
	if toward.length_squared() == 0.0: return "Nonzero actual ordinary-primary bearing required"
	var held: Dictionary = _scheduler.reservation_state(_current.id)
	if held.is_empty() or held.state != "recovery" or not _exact(_fixed_record(held),_fixed_record(_current)): return "Actual recovery lease no longer matches the accepted witness"
	var hits: int = _hero.slash(toward.normalized()) # No resource/HP/pose writes.
	var changed: int = 0
	for id: String in SourceIds:
		var actual: Dictionary = _sources[id].state()
		if float(actual.hp) != float(before[id]):
			if float(actual.hp) != maxf(float(before[id])-float(_stats.primary_damage),0.0) or actual.dead != (float(actual.hp)==0.0): return "Unexpected native primary damage/lifecycle: "+id
			changed += 1
		_expected_hp[id] = actual.hp
	var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if hits < 1 or changed != hits or float(_expected_hp[_source_id]) >= float(before[_source_id]) or actions.size() != 1 or actions[0].kind != "primary" or actions[0].hits != hits or not _exact(actions[0].equipment_ids,_kit):
		return "One genuine public primary did not publish matching native hit(s)"
	_lc_hit = {"source_id":_source_id,"clock_s":_scheduler.get_clock(),"geometry":_current.geometry.duplicate(true),"proof":proof.duplicate(true),"action":actions[0].duplicate(true),"hp_before":before,"hp_after":_expected_hp.duplicate(true)}
	return await _lc_tick_safe() # No required kill or second attack.

func _lc_tick_safe() -> String:
	if _lc_stopping: return "Component is retiring"
	var error: String = _tick_barrier_error()
	if not error.is_empty(): return error
	if paused: return "Unexpected component pause during an actual native response"
	_tick_barrier.waiting = true
	var boundary: String = await _tick_barrier.observed
	if _lc_stopping: return "Component retired while awaiting physics"
	_lc_ticks += 1
	if boundary != "post_actor_physics" or paused or _lc_ticks > LC_NATIVE_LIMIT: return "Component post-actor native tick bound failed"
	return _lc_live_error()

func _lc_live_error() -> String:
	if not is_instance_valid(_hero) or not is_instance_valid(_level) or not is_instance_valid(_scheduler) or _hero.dead or _hero.hp != _lc_start_hp or _scheduler.get_clock() > _route_deadline or not _exact(_hero.equipment.snapshot(),_kit): return "Actual component actors/full HP/kit/native budget changed"
	if int(_events.get("contact",0)) != 0 or int(_events.get("fired_blast",0)) != 0 or int(_events.get("completion",0)) != 0 or int(_events.get("exit",0)) != 0 or not _checkpoints.is_empty(): return "Unexpected damage/blast/parent progression event"
	var actual: Dictionary = _level.call("state")
	if not String(actual.configuration_error).is_empty() or not actual.entered.is_empty() or not actual.deaths.is_empty() or actual.completed or actual.exit_state != "clear" or not actual.contact.is_empty(): return "TEST component acquired canonical route/progress state"
	if not _floor_hit(_hero.global_position) or _world_topology() != _topology or absf(_hero.get_world_action_clock()-_scheduler.get_clock()) > TimeEpsilon: return "Actual component floor/topology/native clocks changed"
	for id: String in SourceIds:
		var source: CinderAct3SunboundStalker = _sources[id]
		var state: Dictionary = source.state()
		# A prospective view refusal returns before native lease/cycle admission
		# (C50 lines268-290). Preserve it as diagnostic, without forcing overlap.
		# An admitted source's current view/cancellation remains mandatory.
		if state.hp != _expected_hp[id] or (not String(state.reservation_id).is_empty() and not state.framing_error.is_empty()) or String(state.last_cancel_reason).begins_with("required_view_unsafe"): return "Actual source resources or admitted native current view guard failed: "+id
		if String(state.reservation_id).is_empty() and not String(state.framing_error).is_empty():
			var key: String = id+"|"+String(state.framing_error)+"|"+String(state.last_rejection)
			var row: Dictionary = _lc_declines.get(key,{"source":id,"first_clock_s":_scheduler.get_clock(),"cycle":state.cycle,"framing_error":state.framing_error,"last_rejection":state.last_rejection,"observed_ticks":0})
			row["last_clock_s"] = _scheduler.get_clock()
			row["observed_ticks"] = int(row.observed_ticks)+1
			_lc_declines[key] = row
		if source.is_physics_processing() != (LC_CROSS_IDS.has(id) and not source.dead): return "Declared actual native source eligibility changed: "+id
		if not LC_CROSS_IDS.has(id) and (source.is_physics_processing() or source.global_position != _lc_origins[id] or state.cycle != 0 or not state.reservation_id.is_empty()): return "Unselected TEST source advanced or acquired a lease"
	for record: Dictionary in _scheduler.reservations():
		var id: String = _source_for_record(record)
		if id.is_empty(): return "Actual lease lacks one of the five real owner bodies"
		if not _records.has(record.id):
			_records[record.id] = record.duplicate(true); _phases[record.id] = {}; _active_travel[record.id] = 0.0
		if not _exact(_fixed_record(record),_fixed_record(_records[record.id])): return "Actual held lane/deadline/commit origin changed"
		var source: CinderAct3SunboundStalker = _sources[id]
		var state: Dictionary = source.state()
		var cue: Dictionary = source.get_cue().state()
		if state.reservation_id != record.id or state.phase != record.state or cue.phase != record.state or cue.geometry != record.geometry or cue.source_position != source.global_position or not cue.source_visible: return "Actual source/lane/cue/phase differs"
		_phases[record.id][record.state] = true
		if record.state == "active": _active_travel[record.id] = maxf(float(_active_travel[record.id]),source.global_position.distance_to(record.adapter.start))
		if record.state == "recovery" and (source.global_position.distance_to(record.adapter.planned_endpoint) > PointTolerance or not source.velocity.is_zero_approx()): return "Actual mobile source failed to stop at its native endpoint"
	return ""

func _lc_post_main() -> String:
	_lc_after_main.waiting = true
	var boundary: String = await _lc_after_main.observed
	if boundary != "post_main_process": return "Actual Main/Camera/HUD process boundary unavailable"
	var error: String = _lc_live_error()
	if not error.is_empty(): return error
	var union: Dictionary = _level.call("camera_framing_union","",[],true)
	if not String(union.error).is_empty(): return String(union.error)
	var points: Array = union.points.duplicate()
	points.append_array(_game.call("player_camera_framing_points_for",_hero,_game.get("camera")))
	return String(_game.call("camera_framing_error",points))

func _lc_source_states() -> Dictionary:
	var result: Dictionary = {}
	for id: String in SourceIds:
		if is_instance_valid(_sources.get(id)): result[id] = _sources[id].state()
	return result

func _lc_fired(kind: String) -> void: _event("fired_"+kind)
func _lc_completion(_id: String,_completion: String) -> void: _event("completion")
func _lc_contact(_id: String,_exit: String) -> void: _event("exit")

func _lc_connect(node: Node, signal_name: String, callback: Callable) -> void:
	node.connect(signal_name,callback)
	_lc_connections.append([node,signal_name,callback])

func _lc_watch_node(node: Node) -> void:
	if not is_instance_valid(_game) or node != _game and not _game.is_ancestor_of(node): return
	var id: String = str(node.get_instance_id())
	if not _lc_seen.has(id):
		_lc_seen[id] = true
		_lc_refs.append(weakref(node))

func _lc_dispose() -> String:
	_lc_stopping = true
	if is_instance_valid(_tick_barrier):
		_tick_barrier.call("_wake","component_retiring")
	if is_instance_valid(_lc_after_main) and _lc_after_main.waiting:
		_lc_after_main.waiting = false
		_lc_after_main.observed.emit("component_retiring")
	if node_added.is_connected(_lc_watch_node): node_added.disconnect(_lc_watch_node)
	for connection: Array in _lc_connections:
		var node: Node = connection[0] as Node
		if is_instance_valid(node) and node.is_connected(connection[1],connection[2]): node.disconnect(connection[1],connection[2])
	_lc_connections.clear()
	var clear: bool = true
	if is_instance_valid(_level) and _level.is_inside_tree():
		_level.exit_level() # Actual public in-tree cancellation before child removal.
		for owner: Node3D in (_level.call("scheduler_bindings").owners as Dictionary).values():
			var control: Dictionary = _scheduler.source_control_state(owner)
			clear = clear and not control.is_empty() and control.reservations.is_empty()
	if is_instance_valid(_game):
		var effects: PixelEffects = _game.get("fx") as PixelEffects
		if effects != null: effects.clear()
		_game.queue_free()
	_game = null
	if is_instance_valid(_lc_after_main):
		_lc_refs.append(weakref(_lc_after_main)); _lc_after_main.queue_free()
	_lc_after_main = null
	if is_instance_valid(_tick_barrier): _lc_refs.append(weakref(_tick_barrier))
	_free_tick_barrier()
	var scene_ref: WeakRef = weakref(_lc_scene) if _lc_scene != null else null
	_lc_scene = null
	var released: bool = false
	for _frame: int in range(120):
		await process_frame
		released = true
		for reference: WeakRef in _lc_refs:
			if reference.get_ref() != null: released = false
		if released: break
	await create_timer(0.15,true,false,true).timeout
	var no_cache: bool = _lc_scene_path.is_empty() or not ResourceLoader.has_cached(_lc_scene_path)
	var scene_gone: bool = scene_ref == null or scene_ref.get_ref() == null
	_level = null; _hero = null; _scheduler = null; _sources.clear()
	_floor = null; _motifs = null; _exit_cue = null
	return "" if clear and released and no_cache and scene_gone and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty() else "Public component cleanup left native owners/nodes/cues/cache"


## Actual paused native portrait adapter. No canonical component-save authority.
var _lp_draw_seen: bool = false
var _lp_png_path: String = ""

func _lp_view_error() -> String:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	if camera == null or hud == null or camera != _hero.get_viewport().get_camera_3d() or camera.get_world_3d() != _hero.get_world_3d(): return "Actual native Camera/HUD/world required"
	var union: Dictionary = _level.call("camera_framing_union","",[],true)
	if not String(union.get("error","Missing complete current union")).is_empty(): return String(union.get("error"))
	var points: Array = (union.points as Array).duplicate()
	points.append_array(_game.call("player_camera_framing_points_for",_hero,camera))
	return String(_game.call("camera_framing_error_for_context",points,_hero,camera,hud))

func _lp_native() -> Dictionary:
	var native: Dictionary = {}
	for id: String in SourceIds:
		var saved: Dictionary = (_sources[id] as CinderAct3SunboundStalker).snapshot_state()
		if saved.is_empty(): return {}
		native[id] = saved
	var player: Dictionary = _hero.snapshot_state()
	var scheduler: Dictionary = _scheduler.snapshot_state(_level.call("scheduler_bindings"))
	if player.is_empty() or scheduler.is_empty(): return {}
	var ids: Dictionary = {"main":str(_game.get_instance_id()),"hero":str(_hero.get_instance_id()),"level":str(_level.get_instance_id()),"scheduler":str(_scheduler.get_instance_id()),"camera":str((_game.get("camera") as Node).get_instance_id())}
	for id: String in SourceIds: ids[id] = str((_sources[id] as Node).get_instance_id())
	return {"player":player,"native_sources":native,"scheduler":scheduler,"component_observation":_level.call("state"),"actions":_actions.duplicate(true),"events":_events.duplicate(true),"deaths":_death_events.duplicate(true),"checkpoints":_checkpoints.duplicate(),"input":_game.call("get_input_observation_state"),"native_ids_decimal_text":ids}

func _lp_labels(node: Node, rows: Array) -> void:
	if node is Label:
		var label: Label = node as Label
		rows.append([String(_game.get_path_to(label)),label.text,label.is_visible_in_tree(),label.global_position,label.size,label.get_theme_font_size("font_size")])
	for child: Node in node.get_children(): _lp_labels(child,rows)

func _lp_optics() -> Dictionary:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	var labels: Array = []
	_lp_labels(hud,labels)
	return {"camera":[camera.global_transform,camera.projection,camera.keep_aspect,camera.size,camera.near,camera.far,camera.h_offset,camera.v_offset,camera.frustum_offset,camera.cull_mask],"hud":[hud.visible,hud.combat_safe_rect(),labels]}

func _lp_render(node: Node, rows: Array) -> void:
	if node is Node3D:
		var physical: Node3D = node as Node3D
		var row: Array = [String(_level.get_path_to(node)),str(node.get_instance_id()),physical.transform,physical.global_transform,physical.visible,physical.is_visible_in_tree()]
		if node is CollisionObject3D:
			var body: CollisionObject3D = node as CollisionObject3D
			row.append_array([body.collision_layer,body.collision_mask,node.is_in_group("enemies")])
		if node is CollisionShape3D:
			var collision: CollisionShape3D = node as CollisionShape3D
			row.append_array([collision.disabled,str(collision.shape.get_instance_id()) if collision.shape != null else ""])
		if node is MeshInstance3D:
			var mesh: MeshInstance3D = node as MeshInstance3D
			row.append_array([str(mesh.mesh.get_instance_id()) if mesh.mesh != null else "",str(mesh.material_override.get_instance_id()) if mesh.material_override != null else "",mesh.layers])
		if node is Sprite3D:
			var sprite: Sprite3D = node as Sprite3D
			row.append_array([str(sprite.texture.get_instance_id()) if sprite.texture != null else "",sprite.pixel_size,sprite.offset,sprite.modulate,sprite.layers])
		rows.append(row)
	for child: Node in node.get_children(): _lp_render(child,rows)

func _lp_sha(bytes: PackedByteArray) -> String:
	if bytes.is_empty(): return ""
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK: return ""
	return hasher.finish().hex_encode()

func _lp_portrait(main: Node, level: CinderLevel, hero: CinderPlayer, scheduler: CinderThreatScheduler, warning: Dictionary) -> Dictionary:
	if not _expect(DisplayServer.get_name() != "headless" and paused and main == _game and level == _level and hero == _hero and scheduler == _scheduler,"portrait uses the actual graphical paused component/native context"): return {"error":"Actual graphical paused native context required"}
	var hud: GameHUD = _game.get("hud") as GameHUD
	var bench: CanvasLayer = _game.get("bench") as CanvasLayer
	for _frame: int in range(2): await process_frame
	var source: CinderAct3SunboundStalker = _sources[warning.id]
	var state: Dictionary = source.state()
	var lease: Dictionary = _scheduler.reservation_state(state.reservation_id)
	var problem: String = _lp_view_error()
	var before: Dictionary = _lp_native()
	if not _expect(hud != null and hud.visible and bench != null and not before.is_empty() and problem.is_empty() and state.phase == "warning" and lease.get("armed",false) and lease.get("source_instance_id") == source.get_instance_id(),"actual changed crossing warning/source/full lane/Hero/landing union validates before draw",problem): return {"error":"Current native warning/view validation failed: "+problem}
	var physical: PackedByteArray = var_to_bytes(before)
	var input: PackedByteArray = var_to_bytes(_game.call("get_input_observation_state"))
	var optics: PackedByteArray = var_to_bytes(_lp_optics())
	var render_before: Array = []
	_lp_render(_level,render_before)
	var render_bytes: PackedByteArray = var_to_bytes(render_before)
	var nonempty: bool = not physical.is_empty() and not input.is_empty() and not optics.is_empty() and not render_before.is_empty() and not render_bytes.is_empty()
	if not _expect(nonempty,"complete typed native/input/Camera/HUD/render witnesses are nonempty before equality"): return {"error":"Empty native portrait witness"}
	var bench_visible: bool = bench.visible
	hud.hide_overlay()
	bench.visible = false
	_lp_draw_seen = false
	RenderingServer.frame_post_draw.connect(_lp_on_draw)
	for _frame: int in range(120):
		await process_frame
		if _lp_draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(_lp_on_draw): RenderingServer.frame_post_draw.disconnect(_lp_on_draw)
	var picture: Image = root.get_texture().get_image() if _lp_draw_seen else null
	hud.show_pause()
	bench.visible = bench_visible
	var after: Dictionary = _lp_native()
	var render_after: Array = []
	_lp_render(_level,render_after)
	problem = _lp_view_error()
	var unchanged: bool = not after.is_empty() and physical == var_to_bytes(after) and input == var_to_bytes(_game.call("get_input_observation_state")) and optics == var_to_bytes(_lp_optics()) and render_bytes == var_to_bytes(render_after)
	if not _expect(_lp_draw_seen and picture != null and picture.get_size().x in [339,340] and picture.get_size().y == 736 and paused and unchanged and problem.is_empty() and bench.visible == bench_visible and hud.visible,"actual paused native draw preserves full states/input/Camera/HUD/render identities and restores overlay",str({"draw":_lp_draw_seen,"size":picture.get_size() if picture != null else Vector2i.ZERO,"unchanged":unchanged,"view":problem})): return {"error":"Native paused draw preservation failed"}
	var folder: String = "res://captures/act3/twin-suns-arrangement/crossing-portrait-%d-%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	_lp_png_path = folder.path_join("01-declared-challenge-crossing-warning.png")
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK and picture.save_png(_lp_png_path) == OK,"actual graphical crossing PNG written after observed draw"): return {"error":"Native PNG write failed"}
	var stamps: Dictionary = {"native":physical,"input":input,"optics":optics,"render":render_bytes}
	var hashes: Dictionary = {}
	for key: String in stamps:
		var digest: String = _lp_sha(stamps[key])
		var path: String = folder.path_join(key+".var.bin")
		var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
		if not _expect(digest.length() == 64 and file != null,"nonempty typed portrait witness persists: "+key): return {"error":"Typed portrait witness cannot be written"}
		file.store_buffer(stamps[key]); file.flush(); file.close()
		if not _expect(FileAccess.get_sha256(path) == digest,"native typed portrait witness hash joins actual bytes: "+key): return {"error":"Typed portrait hash mismatch"}
		hashes[key] = {"sha256":digest,"bytes":(stamps[key] as PackedByteArray).size(),"path":key+".var.bin"}
	var receipt: Dictionary = {"schema_version":1,"test_only":true,"kind":"a3-l1-declared-crossing-depth-portrait-1","runtime_sha256":FileAccess.get_sha256(RuntimePath),"fixture_sha256":FileAccess.get_sha256(PRODUCER_PATH),"png_sha256":FileAccess.get_sha256(_lp_png_path),"actual_dimensions":[picture.get_size().x,picture.get_size().y],"clock_s":_scheduler.get_clock(),"warning_source":warning.id,"phase":state.phase,"cycle":state.cycle,"reservation_id":state.reservation_id,"source_position":Codec.vector3(source.global_position),"hero_position":Codec.vector3(_hero.global_position),"recipe_id":LC_Runtime.CHALLENGE_RECIPE,"native_state_input_optics_render_unchanged":unchanged,"typed_witnesses":hashes,"parent_route_or_save_credit":false,"scope":"One actual paused declared Challenge crossing warning view. Public HUD overlay and bench hidden for capture and restored before exact comparison. No source hidden, parent earned arrival, canonical checkpoint/save, full route or human balance credit."}
	var wire: String = ExactJson.stringify(receipt)
	var file: FileAccess = FileAccess.open(_lp_png_path+".json",FileAccess.WRITE)
	if not _expect(not wire.is_empty() and file != null,"finite exact actual crossing portrait receipt opens"): return {"error":"Portrait receipt unavailable"}
	file.store_string(wire+"\n");file.flush();file.close()
	print("L1 CROSSING PORTRAIT: ",ProjectSettings.globalize_path(_lp_png_path))
	return {"error":"","path":ProjectSettings.globalize_path(_lp_png_path),"png_sha256":FileAccess.get_sha256(_lp_png_path),"scope":"actual declared changed crossing warning still; no parent route/save authority"}

func _lp_on_draw() -> void:
	_lp_draw_seen = true
