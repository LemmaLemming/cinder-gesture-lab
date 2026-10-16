extends "res://tests/acts/act3/mirror_sea_production_warning_smoke.gd"
## ORIGINAL-WRITER ONLY: genuine fresh MAIN Challenge L3 entrance and first
## held managed Echo warning. SOURCE-ONLY until Root imports/runs this file.
## TEST predecessor A3-L2 floor/prefix12 are explicit metadata. No L3 aggregate,
## resource, pose, clock, entry, death, generation or lease is manufactured.
## Native original sources/codec/layout must remain exact until producer closes.

const P3_PATH: String = "res://tests/acts/act3/mirror_sea_arrangement_smoke.gd"
const P3_ROOT: String = "res://tests/acts/act3/fixtures/a3_l3_arrangement/legacy"
# New narrow TEST scene uses the unchanged existing native live-level script.
const P3_PREDECESSOR: String = "res://tests/acts/act3/fixtures/a3_l3_arrangement/predecessor.tscn"
const P3_CODEC: String = "res://scripts/acts/act3/mirror_sea_codec.gd"
const P3_LAYOUT: String = "res://data/campaign/act3/mirror_sea_layout_candidate.json"
const P3_OLD_PINS: Dictionary = {
	RUNTIME_PATH:"4af8680418d0b7449f0750315a8672282f652d5d782878f5c4e7206d6a362b72",
	P3_CODEC:"7fdfe2a8f259190ba223197725ab5b2a9ce6533ce580e55ef08ef13d81774ca6",
	P3_LAYOUT:"4cbba73342e4f8658dfe67e838de7dfa4e4802b91ef192f6802cf0a68c3e1a2a",
}
const P3_KEYS: Array[String] = ["api_revision","schema_version","world","scheduler","sources","route","ring","view"]
const P3_Attempts = preload("res://scripts/campaign/attempts.gd")
const P3_Game = preload("res://scripts/game.gd")
var _p3_done: bool = false
var _p3_complete: bool = false
var _p3_preview: Node
var _p3_prefix: Array[String] = []
var _p3_seed: Dictionary = {}
var _p3_entrance: Dictionary = {}
var _p3_pins: Dictionary = {}
var _p3_uids: Dictionary = {}
var _p3_files: Dictionary = {}
var _p3_samples: Dictionary = {}
var _p3_driver_observations: int = 0
var _p3_last_clock: float = 0.0

func _initialize() -> void:
	_run.call_deferred()
	# This timer bounds a running process loop, not a suspended engine/OS.
	create_timer(600.0,true,false,true).timeout.connect(_p3_watchdog)

func _run() -> void:
	var selected: PackedStringArray = OS.get_cmdline_user_args()
	if selected == PackedStringArray(["--east-component"]) or selected == PackedStringArray(["--east-component-portrait"]):
		await _eca_run(String(selected[0]))
		return
	if selected == PackedStringArray(["--pure"]):
		var error: String = _pure_arrangement_checks()
		_expect(error.is_empty(), "pure closed profiles/recipes/malformed metadata and complete whole-east translation remain immutable", error)
		_p3_done = true
		print("Mirror Sea arrangement PURE: %d checks/%d failures; metadata/derivation only; no native capture credit." % [_checks, _failures])
		quit(0 if _failures == 0 else 1)
		return
	if selected == PackedStringArray(["--legacy"]) or selected == PackedStringArray(["--current-persistence"]):
		if selected[0] == "--legacy": _p3_complete = await _p3t_run_legacy()
		else: _p3_complete = await _p3t_run_current_persistence()
		await _p3_finish()
		return
	var reason: String = ""
	if OS.get_cmdline_user_args() != PackedStringArray(["--produce-legacy"]): reason = "only --produce-legacy is supported by the original writer"
	if reason.is_empty():
		for path: String in P3_OLD_PINS:
			if FileAccess.get_sha256(path) != P3_OLD_PINS[path]: reason = "original writer pin differs before production: "+path; break
	if reason.is_empty() and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(P3_ROOT)): reason = "immutable legacy folder already exists; preserve/relocate failed originals explicitly before any new run"
	if reason.is_empty(): reason = await _open()
	if not _expect(reason.is_empty(),"actual public predecessor creates genuine zero-tick MAIN Challenge L3; no handmade L3 seed",reason):
		await _p3_finish(); return
	_p3_entrance = _shell.capture_campaign_snapshot()
	if not _p3_legacy_unit(_p3_entrance,false) or not _p3_prepare_archive() or not _p3_archive("entrance",_p3_entrance,{}):
		await _p3_finish(); return
	print("Mirror Sea arrangement producer: genuine old Challenge MAIN entrance/Scheduler1 archived")
	_shell.resume_campaign()
	if not _expect(not paused,"public resume starts unchanged ordinary threshold route"):
		await _p3_finish(); return
	reason = await _travel_entry(0)
	if reason.is_empty(): reason = _first_source()
	if reason.is_empty(): reason = await _clear_stalker()
	if not _expect(reason.is_empty(),"ordinary viewport swipes/first taps genuinely clear only threshold Stalker",reason):
		print("FIRST MEANINGFUL ORIGINAL PRODUCER FAILURE: ",reason,"; ",_diagnostic())
		await _p3_finish(); return
	reason = await _travel_entry(1)
	if reason.is_empty(): reason = _first_echo_ready()
	if reason.is_empty(): reason = await _unarmed_warning()
	if not _expect(reason.is_empty(),"genuine first two entries earn managed initial Echo warning",reason):
		print("FIRST MEANINGFUL ORIGINAL PRODUCER FAILURE: ",reason,"; ",_diagnostic())
		await _p3_finish(); return
	if not _shell.request_pause_deferred():
		_expect(false,"actual public complete-tick warning pause is accepted")
		await _p3_finish(); return
	reason = await _p3_wait("pause","A3-L3")
	var held: Dictionary = _shell.capture_campaign_snapshot() if reason.is_empty() else {}
	var receipt: Dictionary = _p3_held_receipt()
	if not _expect(reason.is_empty() and not held.is_empty() and not receipt.is_empty(),"actual paused unarmed native warning remains before lock",reason+"; "+str(receipt)) or not _p3_legacy_unit(held,true) or not _p3_archive("first-echo-held",held,receipt):
		await _p3_finish(); return
	for path: String in _p3_pins:
		if not _expect(FileAccess.get_sha256(path) == _p3_pins[path],"every original producer source/UID remains frozen: "+path): await _p3_finish(); return
	if not _p3_write("manifest.json",{"schema_version":1,"kind":"a3-l3-original-challenge-arrangement-legacy-1","test_only":true,"files":_p3_files.duplicate(true),"source_pins":_p3_pins,"resource_uid_text":_p3_uids,"samples":_p3_samples.duplicate(true),"driver_observations":_p3_driver_observations,"last_native_scheduler_clock_s":_p3_last_clock,"canonical_registry_sha256":FileAccess.get_sha256(ProductionRegistry.DATA_PATH),"execution_provenance":"Original Root runner command/sources/result/native.log govern actual HEAD, input custody, diagnostics and terminal outcome. This manifest alone grants no pass.","scope":"Actual old Challenge MAIN entrance Scheduler1 and first held Echo Scheduler3, real threshold Stalker defeat/two entries/latest second-entry checkpoint. TEST predecessor floor/prefix12 only. Whole native current/session/checkpoint and raw format2 Stores, original future-east recipe. No fabricated L3 state, earned east/resonance/final/contact/full-route, new reader or portrait credit."}):
		await _p3_finish(); return
	_p3_complete = true
	print("Mirror Sea arrangement producer: genuine old held Echo/Scheduler3 and immutable manifest archived")
	await _p3_finish()

func _open() -> String:
	_test_root = "user://test-a3-l3-original-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_canonical_registry_bytes = FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(_canonical_registry_bytes)
	if not parsed is Dictionary: return "canonical registry unavailable"
	_raw_registry = parsed.duplicate(true)
	for row: Dictionary in _raw_registry.levels:
		if row.id == "A3-L2": row.scene_path = P3_PREDECESSOR
	var registry: CinderCampaignRegistry = ProductionRegistry.new(_raw_registry)
	_p3_prefix.assign(registry.main_route().slice(0,12))
	if not registry.last_error.is_empty() or _p3_prefix.size() != 12 or _p3_prefix[-1] != "A3-L2" or registry.entry("A3-L3").scene_path != LEVEL_PATH: return "TEST predecessor prefix12/actual MAIN L3 row differs: "+registry.last_error
	var predecessor: Dictionary = await _p3_predecessor()
	if predecessor.is_empty(): return "genuine native predecessor writers unavailable"
	if not _p3_capture_pins(): return "original source/UID custody unavailable"
	var model: CinderCampaignAttempts = P3_Attempts.new(registry)
	_p3_seed = model.state()
	_p3_seed.completed_main = _p3_prefix.duplicate() # TEST ONLY historical prefix.
	_p3_seed.story = {"kind":"story","level_id":"A3-L2","snapshot":predecessor.duplicate(true),"checkpoint":predecessor.duplicate(true)}
	var store: CinderSaveStore = ProductionStore.new(_test_root+"campaign.json")
	store.payload_validator = model.saved_payload_error
	var error: String = model.state_error(_p3_seed)
	if not error.is_empty() or not store.write_payload(_p3_seed): return "detached TEST predecessor seed rejected: "+error+"; "+store.last_error
	_shell = ProductionShell.new()
	_game = _shell
	if not _shell.configure_runtime(_raw_registry,_test_root+"campaign.json",_test_root+"settings.json",_test_root+"preferences.json"): return "isolated actual Shell configuration rejected"
	root.add_child(_shell)
	error = await _p3_wait("title")
	if not error.is_empty(): return error
	if not _exact(_shell.attempts.state(),_p3_seed): return "actual startup changed TEST predecessor session"
	_shell.menu.show_settings()
	var selector: OptionButton = _shell.menu.find_child("DifficultySelector",true,false) as OptionButton
	if selector == null: return "actual public menu difficulty selector missing"
	var chosen: int = -1
	for i: int in range(selector.item_count):
		if selector.get_item_metadata(i) == "challenge": chosen = i
	if chosen < 0: return "canonical Challenge option missing"
	selector.select(chosen)
	selector.item_selected.emit(chosen)
	var preference: CinderSaveStore = ProductionStore.new(_test_root+"preferences.json")
	if _shell.get_difficulty_preference() != "challenge" or not _exact(preference.read_payload(),{"schema_version":1,"profile_id":"challenge"}) or not _exact(_shell.attempts.state(),_p3_seed): return "public Challenge preference failed or changed old native predecessor"
	_shell.menu.continue_story_requested.emit()
	error = await _p3_wait("resume","A3-L2")
	if not error.is_empty(): return error
	if not _exact(_shell.capture_campaign_snapshot(),predecessor): return "public MAIN Continue changed the genuine TEST predecessor"
	if not _shell.active_level.request_completion("test-only-predecessor-clear"): return "TEST predecessor public completion rejected"
	error = await _p3_wait("resume","A3-L2")
	if not error.is_empty(): return error
	if not _shell.active_level.is_completed() or _shell.attempts.state().completed_main != _p3_prefix: return "TEST predecessor completion changed the allowed prefix"
	if not _shell.active_level.request_contact_exit("test-only-fresh-mirror-sea-entry",_shell.player): return "TEST predecessor public contact rejected"
	error = await _p3_wait("resume","A3-L3")
	if not error.is_empty(): return error
	_hero = _shell.player
	_level = _shell.active_level
	_kit = _hero.equipment.snapshot()
	_stats = _hero.equipment.resolved_stats()
	_hero_hp = _hero.hp
	_shells = _hero.shells
	if float(_stats.primary_damage) != 20.0 or _hero_hp != _hero.max_hp: return "genuine carried starter kit/resources differ before L3 gameplay"
	error = _bind_runtime() # One actual observer/binding installation only.
	if not error.is_empty(): return error
	var unit: Dictionary = _shell.capture_campaign_snapshot()
	if unit.is_empty() or _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0 or not _hero.get_world_action_records().is_empty() or not (_level.get("sources") as Dictionary).is_empty() or not unit.level.local.route.entries.is_empty() or not unit.level.local.route.deaths.is_empty() or unit.level.local.world.profile_id != "challenge" or unit.shell.difficulty_at_entry != "challenge": return "public contact did not create genuine source-free Challenge L3 zero-clock entrance"
	return String(_level.call("runtime_error"))

func _p3_predecessor() -> Dictionary:
	paused = true
	_p3_preview = MainScene.instantiate()
	_p3_preview.set("level_scene_path",P3_PREDECESSOR)
	root.add_child(_p3_preview)
	_p3_preview.call("open_bench")
	await process_frame
	var actor: CinderPlayer = _p3_preview.get("player") as CinderPlayer
	var level: CinderLevel = _p3_preview.get("active_level") as CinderLevel
	var camera: Camera3D = _p3_preview.get("camera") as Camera3D
	var result: Dictionary = {}
	if _expect(actor != null and level != null and camera != null and level.level_id == "A3-L2" and String(_p3_preview.get("level_load_error")).is_empty(),"existing TEST predecessor constructs through genuine Main"):
		var player: Dictionary = actor.snapshot_state()
		var local: Dictionary = level.snapshot_state()
		var input: Dictionary = _p3_preview.call("get_input_observation_state")
		if _expect(paused and not player.is_empty() and not local.is_empty() and actor.get_world_action_clock() == 0.0 and actor.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty(),"native initial predecessor writers contain no fabricated gameplay",actor.last_snapshot_error+"; "+level.last_snapshot_error):
			var anchor: Vector2 = input.anchor_normalized
			result = {"schema_version":1,"level_id":"A3-L2","scene_path":P3_PREDECESSOR,"paused":true,"equipment_ids":actor.equipment.snapshot(),"player":player,"level":local,"shell":{"api_revision":ProductionShell.SHELL_API,"anchor_normalized":[anchor.x,anchor.y],"input_sequence":input.sequence,"last_input_observation":{},"camera_focus":ProductionValue.vector3(camera.global_position-P3_Game.CAMERA_OFFSET),"shake_left_s":0.0,"difficulty_at_entry":"standard"}}
	if not await _p3_dispose_preview(): return {}
	return result

func _p3_wait(page: String, active_id: String = "") -> String:
	for _frame: int in range(120):
		await process_frame
		if not is_instance_valid(_shell): return "actual Shell was freed while settling"
		if not _shell.campaign_error.is_empty(): return _shell.campaign_error
		if not paused or _shell.is_pause_requested() or _shell.menu.page_name() != page: continue
		if not active_id.is_empty() and (not is_instance_valid(_shell.active_level) or _shell.active_level.level_id != active_id): continue
		await process_frame
		return "" if paused and _shell.campaign_error.is_empty() and _shell.menu.page_name() == page else "public paused operation changed during its deferred/UI boundary"
	return "actual operation exceeded120 process observations: "+page+"/"+active_id+"; "+str({"paused":paused,"page":_shell.menu.page_name(),"error":_shell.campaign_error})

func _tick() -> String:
	if _p3_done: return "original producer is retiring"
	if _ec_running: return await _ec_tick()
	_p3_driver_observations += 1
	if _p3_driver_observations > 6000: return "original first-two-entry producer exceeded6000 observer calls"
	var error: String = await super._tick()
	if is_instance_valid(_scheduler): _p3_last_clock = _scheduler.get_clock()
	return error

func _p3_legacy_unit(unit: Dictionary, held: bool) -> bool:
	if not _expect(not unit.is_empty() and paused and unit.level_id == "A3-L3" and unit.scene_path == LEVEL_PATH and unit.shell.difficulty_at_entry == "challenge" and unit.level.local_snapshot_version == 1,"genuine old Challenge MAIN L3 whole unit retains original outer1"): return false
	var local: Dictionary = unit.level.local
	if not _expect(ProductionValue.keys_error(local,P3_KEYS).is_empty() and local.api_revision == "act3-mirror-sea-snapshot-1" and local.schema_version == 1 and local.world.world_revision == 1 and local.world.layout_sha256 == P3_OLD_PINS[P3_LAYOUT] and local.world.profile_id == "challenge" and local.scheduler.profile.id == "challenge" and local.route.entries.size() == (2 if held else 0) and local.route.deaths.size() == (1 if held else 0) and local.ring.stage == "uninstalled" and local.ring.mechanism.is_empty() and not unit.level.progress.completed and unit.level.progress.contact_exit_id.is_empty(),"literal old eight-key API1/schema1/base-world1 contains only the real current prefix"): return false
	var pair: Dictionary = {"hero":unit.player,"level":unit.level}
	var error: String = _pair_error(pair)
	if not _expect(error.is_empty(),"actual complete old native pair/pure/ExactJSON checks remain authoritative",error): return false
	var future: Dictionary = _p3_future_east()
	var original_x: float = Vector3(0.65,0,0).x # Compare the actual native Vector3 component, not a different float64 literal.
	if not _expect(not future.is_empty() and future.no_live_owner and future.translation_x == original_x and future.route[0].position[0] == original_x and future.route[1].position[0] == original_x and future.slash_origin[0] == original_x,"uninstalled future east definition remains actual canonical X0.65; no dormant owner is invented"): return false
	if not held:
		return _expect(local.scheduler.schema_version == 1 and local.scheduler.get("authored_source_cycles",{}).is_empty() and local.sources.is_empty() and local.scheduler.reservations.is_empty() and unit.player.world_actions.clock_s == 0.0 and unit.player.world_actions.history.is_empty() and unit.level.progress.checkpoint_ids.is_empty(),"actual source-free zero-clock entrance preserves native Scheduler1/no journal/no L3 history")
	var checkpoint_ids: Array[String] = _level.call("mirror_sea_codec_checkpoint_ids")
	if not _expect(checkpoint_ids.size() == 6,"unchanged six-entry checkpoint catalogue is present"): return false
	var expected: Dictionary = {}
	for id: String in checkpoint_ids.slice(0,2): expected[id] = "encounter"
	if not _expect(ProductionValue.keys_error(local.sources,[STALKER_ID,ECHO_ID]).is_empty() and local.route.deaths.has(STALKER_ID) and local.sources[STALKER_ID].kind == "stalker" and local.sources[STALKER_ID].actor.dead and local.sources[STALKER_ID].actor.hp == 0.0 and not _stalker.is_in_group("enemies") and _events.get("stalker_death",0) == 1 and _exact(unit.level.progress.checkpoint_ids,expected) and unit.level.progress.checkpoint_id == checkpoint_ids[1] and unit.level.progress.checkpoint_kind == "encounter","real threshold tombstone/two entries/latest delivered CP2 are exact, not an entrance Retry policy"): return false
	var echo_packet: Dictionary = local.sources[ECHO_ID]
	var journal: Variant = local.scheduler.get("authored_source_cycles")
	return _expect(local.scheduler.schema_version == 3 and journal is Dictionary and journal.get("sources") is Array and journal.sources.size() == 1 and journal.sources[0] is Dictionary and journal.sources[0].source_id == ECHO_ID and echo_packet.kind == "echo" and echo_packet.actor.api_revision == "act3-mirror-echo-source-2" and echo_packet.actor.schema_version == 2 and echo_packet.actor.generation == 1 and echo_packet.actor.alive and echo_packet.actor.hp == 36.0 and echo_packet.actor.source_hits == 0 and echo_packet.actor.lifecycle.terminal_receipts.is_empty() and echo_packet.playback.status == "running" and not echo_packet.playback.cursor.armed and _hero.hp == _hero_hp and _hero.shells == _shells and int(_events.get("fired_blast",0)) == 0,"held first managed Echo retains Source2/Playback2/full Scheduler3 actual journal and ordinary-only resources")

func _p3_held_receipt() -> Dictionary:
	if not is_instance_valid(_echo) or not is_instance_valid(_scheduler): return {}
	var source: Dictionary = _echo.call("get_source_state")
	var playback: Dictionary = _echo.call("state")
	var control: Dictionary = _scheduler.source_control_state(_echo)
	if source.source_id != ECHO_ID or source.generation != 1 or source.phase != "warning" or playback.status != "running" or playback.cursor.armed or String(playback.reservation_id).is_empty() or control.get("reservations",[]).size() != 1: return {}
	var lease: Dictionary = control.reservations[0]
	if control.source_instance_id != _echo.get_instance_id() or lease.source_instance_id != _echo.get_instance_id() or lease.id != playback.reservation_id or lease.armed or lease.adapter.kind != "authored_replay" or lease.adapter.locked or lease.profile_id != "challenge" or control.clock_s != _scheduler.get_clock() or _scheduler.get_clock() >= float(lease.lock_from_s): return {}
	var deadlines: Dictionary = {}
	for key: String in FIXED_DEADLINES: deadlines[key] = lease[key]
	return {"source_id":ECHO_ID,"source_epoch":source.source_epoch,"generation":source.generation,"phase":"warning","status":playback.status,"reservation_id":lease.id,"clock_s":_scheduler.get_clock(),"deadlines":deadlines,"actual_source_instance_id_decimal_text":str(_echo.get_instance_id()),"source_position":ProductionValue.vector3(_echo.global_position)}

func _p3_future_east() -> Dictionary:
	var definition: Dictionary = _level.call("native_definition","l3-useful-east-echo")
	if not definition.get("route") is Array or definition.route.size() != 2 or not definition.get("slash") is Dictionary: return {}
	var route: Array[Dictionary] = []
	for point: Dictionary in definition.route: route.append({"position":ProductionValue.vector3(point.position),"at_s":point.at_s})
	# JSON-native observation of a pure immutable recipe, not live future state.
	return {"definition_id":definition.definition_id,"translation_x":float((definition.route[0].position as Vector3).x),"route":route,"slash_origin":ProductionValue.vector3(definition.slash.world_origin),"slash_direction":ProductionValue.vector3(definition.slash.direction),"raw_role":definition.raw_role.duplicate(true),"timing_floors":definition.timing_floors.duplicate(true),"no_live_owner":not (_level.get("sources") as Dictionary).has("l3-useful-east-echo")}

func _p3_prepare_archive() -> bool:
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(P3_ROOT)) == OK,"new immutable original raw archive directory opens"): return false
	var ignore: FileAccess = FileAccess.open(P3_ROOT.path_join(".gdignore"),FileAccess.WRITE)
	if not _expect(ignore != null,"raw legacy archive is inert; parent fixture directory stays importable"): return false
	ignore.close()
	_p3_files[".gdignore"] = {"sha256":FileAccess.get_sha256(P3_ROOT.path_join(".gdignore")),"bytes":0}
	return _p3_write("registry.native.json",_raw_registry) and _p3_write("start-session.native.json",_p3_seed) and _p3_write("source-pins.json",{"source_pins":_p3_pins,"resource_uid_text":_p3_uids})

func _p3_archive(label: String, unit: Dictionary, receipt: Dictionary) -> bool:
	var session: Dictionary = _shell.attempts.state()
	var checkpoint: Dictionary = session.story.checkpoint
	if not _expect(paused and session.side_attempt == null and session.completed_main == _p3_prefix and session.story.level_id == "A3-L3" and _exact(session.story.snapshot,unit) and _exact(_shell.capture_campaign_snapshot(),unit),"full actual MAIN session/current snapshot joins native capture: "+label): return false
	if not _expect((_exact(checkpoint,unit) if label == "entrance" else (checkpoint.level.progress.checkpoint_id == (_level.call("mirror_sea_codec_checkpoint_ids") as Array)[1] and checkpoint.level.local.route.entries.size() == 2 and checkpoint.level.local.route.deaths.has(STALKER_ID))),"actual protected checkpoint is entrance or genuine latest CP2 as appropriate: "+label): return false
	var error: String = _disk_error(session)
	if not _expect(error.is_empty(),"independent native primary Store equals actual complete MAIN session: "+label,error): return false
	var folder: String = P3_ROOT.path_join(label)
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"new sample folder never overwrites originals: "+label): return false
	if not _p3_write(label+"/unit.native.json",unit) or not _p3_write(label+"/session.native.json",session) or not _p3_write(label+"/checkpoint.native.json",checkpoint): return false
	for pair: Array in [["campaign.json","campaign.store.json"],["preferences.json","preferences.store.json"],["campaign.json.bak","campaign.store.json.bak"]]:
		if not FileAccess.file_exists(_test_root+pair[0]):
			return _expect(false,"required native raw Store is absent: "+pair[0])
		if not _p3_copy(label+"/"+pair[1],_test_root+pair[0]): return false
	var ids: Dictionary = {"shell":str(_shell.get_instance_id()),"world":str(_shell.world.get_instance_id()),"level":str(_level.get_instance_id()),"hero":str(_hero.get_instance_id()),"scheduler":str(_scheduler.get_instance_id()),"camera":str(_shell.camera.get_instance_id())}
	for id: String in (_level.get("sources") as Dictionary): ids[id] = str(((_level.get("sources") as Dictionary)[id] as Node).get_instance_id())
	if not _p3_write(label+"/receipt.json",{"schema_version":1,"test_only":true,"sample":label,"held_warning":receipt,"actual_native_ids_decimal_text":ids,"future_east_immutable_recipe":_p3_future_east(),"whole_exact_wire_sha256":ExactJson.stringify(unit).sha256_text(),"session_exact_wire_sha256":ExactJson.stringify(session).sha256_text(),"raw_store_policy":"Actual native format2 primary/backup/preferences bytes copied directly, never JSON reencoded or manufactured."}): return false
	_p3_samples[label] = {"unit":label+"/unit.native.json","session":label+"/session.native.json","checkpoint":label+"/checkpoint.native.json","receipt":label+"/receipt.json"}
	return _expect(_exact(_shell.capture_campaign_snapshot(),unit) and _exact(_shell.attempts.state(),session),"archival writes preserve full native current/protected/session state: "+label)

func _p3_capture_pins() -> bool:
	var paths: Array[String] = [P3_PATH,RUNTIME_PATH,P3_CODEC,P3_LAYOUT,LEVEL_PATH,"res://tests/acts/act3/mirror_sea_production_warning_smoke.gd","res://tests/acts/act3/mirror_sea_frontier_smoke.gd","res://scripts/acts/act3/mirror_echo.gd","res://scripts/acts/act3/mirror_echo_codec2.gd","res://scripts/acts/act3/mirror_echo_rule_room.gd","res://scripts/acts/act3/mirror_sea_scenery.gd","res://scripts/acts/act3/mirror_sea_vignettes.gd","res://scripts/acts/act3/sunbound_stalker.gd","res://scripts/campaign/shell.gd","res://scripts/campaign/level.gd","res://scripts/campaign/attempts.gd","res://scripts/campaign/save_store.gd","res://scripts/campaign/exact_json.gd","res://scripts/combat/threat_scheduler.gd","res://scripts/combat/authored_enemy_sequence.gd","res://scripts/combat/replay_playback.gd","res://scripts/combat/replay_witness.gd","res://scripts/combat/replay_footprint.gd","res://scripts/player.gd",P3_PREDECESSOR,"res://tests/fixtures/campaign/live_a1_l2.tscn","res://tests/fixtures/campaign/live_level.gd",ProductionRegistry.DATA_PATH]
	for path: String in paths:
		var digest: String = FileAccess.get_sha256(path)
		if not _expect(digest.length() == 64,"original named source exists: "+path): return false
		_p3_pins[path] = digest
		if FileAccess.file_exists(path+".uid"):
			_p3_pins[path+".uid"] = FileAccess.get_sha256(path+".uid")
			_p3_uids[path] = FileAccess.get_file_as_string(path+".uid").strip_edges()
		elif path.ends_with(".tscn"):
			var uid: int = ResourceLoader.get_resource_uid(path)
			if uid != ResourceUID.INVALID_ID: _p3_uids[path] = ResourceUID.id_to_text(uid)
	return _expect(FileAccess.file_exists(P3_PATH+".uid"),"producer script UID comes only from legitimate Root import")

func _p3_write(relative: String, value: Dictionary) -> bool:
	var wire: String = ExactJson.stringify(value)
	var target: String = P3_ROOT.path_join(relative)
	if not _expect(not wire.is_empty() and not FileAccess.file_exists(target),"new finite ExactJSON original file only: "+relative): return false
	var file: FileAccess = FileAccess.open(target,FileAccess.WRITE)
	if not _expect(file != null,"original archive file opens: "+relative): return false
	file.store_string(wire+"\n"); file.flush()
	var error: Error = file.get_error()
	file.close()
	if not _expect(error == OK and FileAccess.get_file_as_string(target) == wire+"\n","exact original bytes persist: "+relative): return false
	_p3_files[relative] = {"sha256":FileAccess.get_sha256(target),"bytes":FileAccess.get_file_as_bytes(target).size(),"exact_wire_sha256":wire.sha256_text()}
	return true

func _p3_copy(relative: String, source: String) -> bool:
	var target: String = P3_ROOT.path_join(relative)
	var digest: String = FileAccess.get_sha256(source)
	if not _expect(digest.length() == 64 and not FileAccess.file_exists(target) and DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(target)) == OK and FileAccess.get_sha256(source) == digest and FileAccess.get_sha256(target) == digest,"byte-copy actual raw format2 Store without reencoding: "+relative): return false
	_p3_files[relative] = {"sha256":digest,"bytes":FileAccess.get_file_as_bytes(target).size(),"original_user_path":source,"raw_store_copy":true}
	return true

func _p3_collect(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _p3_collect(child,refs)

func _p3_dispose_preview() -> bool:
	if not is_instance_valid(_p3_preview): return true
	var refs: Array[WeakRef] = []
	_p3_collect(_p3_preview,refs)
	var level: CinderLevel = _p3_preview.get("active_level") as CinderLevel
	if is_instance_valid(level): level.exit_level()
	_p3_preview.queue_free()
	_p3_preview = null
	for _frame: int in range(120):
		var clear: bool = true
		for ref: WeakRef in refs: clear = clear and ref.get_ref() == null
		if clear: return _expect(true,"TEST predecessor's actual Main/world/Hero/guard retire normally")
		await process_frame
	return _expect(false,"TEST predecessor retains native nodes past bounded120 observations")

func _p3_watchdog() -> void:
	if _p3_done: return
	_expect(false,"original producer600 process-seconds watchdog expired; archive remains partial")
	await _p3_finish()

func _p3_finish() -> void:
	if _p3_done: return
	_p3_done = true
	if _ec_running or _ec_disposing or not _ec_native_handles.is_empty() or not _ec_scene_handles.is_empty():
		var component_cleanup: String = await _ec_dispose_all()
		_expect(component_cleanup.is_empty(), "declared component native handles/scenes retire before common finish", component_cleanup)
	var prior_clock: float = _scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0
	var actor_clock: float = _hero.get_world_action_clock() if is_instance_valid(_hero) else -1.0
	var actions: Array[Dictionary] = []
	if is_instance_valid(_hero): actions.assign(_hero.get_world_action_records())
	var resources: Dictionary = {"hp":_hero.hp,"shells":_hero.shells,"dead":_hero.dead} if is_instance_valid(_hero) else {}
	var owners: Dictionary = _level.call("scheduler_bindings").owners if is_instance_valid(_level) else {}
	_detach_quiet_observers() # Only fixture callbacks; native callbacks remain.
	if is_instance_valid(_level): _level.exit_level()
	if is_instance_valid(_scheduler) and is_instance_valid(_hero):
		var released: bool = _hero.is_inside_tree() and _scheduler.is_inside_tree() and _hero.get_world_action_clock() == actor_clock and _scheduler.get_clock() == prior_clock and _exact(actions,_hero.get_world_action_records()) and _exact(resources,{"hp":_hero.hp,"shells":_hero.shells,"dead":_hero.dead})
		for owner: Node3D in owners.values():
			var control: Dictionary = _scheduler.source_control_state(owner)
			released = released and not control.is_empty() and control.get("outside_transaction",false) and control.get("reservations",[]).is_empty() and control.clock_s == prior_clock
		_expect(released,"supported inside-tree producer exit releases held owners without resetting clocks/actions/resources")
	# Transport selectors already retire whole hosts with _p3t_close; the
	# inherited helper assumes a live Hero and is unnecessary after that.
	if is_instance_valid(_game): await _dispose_host(false)
	await _p3_dispose_preview()
	if node_added.is_connected(_watch_new_node): node_added.disconnect(_watch_new_node)
	_expect(_canonical_registry_bytes.is_empty() or FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH) == _canonical_registry_bytes,"canonical Registry bytes remain exact")
	_cleanup_owned_path(_test_root)
	if not _eca_selector.is_empty():
		print("Mirror Sea arrangement declared east component TEST: %d checks/%d failures; selector=%s; complete=%s; result_folder=%s; no earned east/canonical parent save/full-route/human balance credit. Original runner closure remains authoritative." % [_checks,_failures,_eca_selector,str(_p3_complete),_eca_result_folder])
	else:
		print("Mirror Sea arrangement TEST: %d checks/%d failures; selector=%s; complete=%s; driver_observations=%d; last_scheduler_clock_s=%.9f; early MAIN transport only; no earned east/full-route/portrait credit." % [_checks,_failures,str(OS.get_cmdline_user_args()),str(_p3_complete),_p3_driver_observations,_p3_last_clock])
	quit(0 if _failures == 0 and _p3_complete else 1)

## SOURCE-ONLY reviewed derivative. Original a2fcab7e6210d924c4cf4006bea4ff22fa7e5dcd2b72cdc4c01a69a2de7e02d7 remains unchanged.
## Adds exact selected profile/recipe identity plus three bounded metadata controls.
## No GDScript parse, engine, native capture, save/restore or gameplay success is implied.
## TEST ONLY fragment for the authorized focused selector. Run only after Root
## seals the real old-writer output and promotes/reviews the draft production files.
## This checks pure metadata/derivation only. Empty route/ring/world placeholders
## below are NOT valid native packets and earn no parent/save/prefix authority.
const ArrangementParent = preload("res://scripts/acts/act3/mirror_sea_level.gd")
const ArrangementHelper = preload("res://scripts/combat/encounter_arrangement.gd")
const ArrangementDifficulty = preload("res://scripts/combat/difficulty.gd")
const ArrangementExact = preload("res://scripts/combat/authored_enemy_sequence.gd")

func _pure_arrangement_checks() -> String:
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ArrangementParent.ARRANGEMENT_PATH))
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ArrangementParent.LAYOUT))
	var rows: Dictionary = {}
	for row: Dictionary in layout.sources: rows[row.id] = row.duplicate(true)
	var rows_before: Dictionary = rows.duplicate(true)
	var selector := ArrangementHelper.new(definition)
	for profile: String in ["assisted", "standard", "challenge"]:
		for legacy: bool in [true, false]:
			var local: Dictionary = _pure_selection_unit(profile, legacy, selector)
			var before: Dictionary = local.duplicate(true)
			var chosen: Dictionary = ArrangementParent.arrangement_constructor(local, definition)
			if not String(chosen.error).is_empty() or chosen.legacy != legacy or not ArrangementExact.exact_equal(local, before): return "pure selection refused or mutated its own input"
			var expected_recipe: String = String(ArrangementParent.LEGACY_RECIPE_IDS[profile] if legacy else definition.current[profile])
			if not chosen.get("descriptor") is Dictionary or chosen.descriptor.get("profile") != profile or chosen.descriptor.get("recipe_id") != expected_recipe: return "pure selected descriptor differs from its exact profile/retained recipe identity"
			var derived: Dictionary = ArrangementParent.arrangement_rows(chosen.descriptor, definition, rows)
			if not String(derived.error).is_empty() or not ArrangementExact.exact_equal(rows, rows_before): return "pure derivation refused or mutated canonical rows"
			var offset: float = 1.0 if profile == "challenge" and not legacy else 0.0
			var expected: Dictionary = rows.duplicate(true)
			if offset == 1.0:
				for key: String in ["local_recipe_offset", "definition_translation_world", "fixed_knot_world", "slash_origin_world"]:
					expected[ArrangementParent.EAST_ID][key][0] = float(expected[ArrangementParent.EAST_ID][key][0]) + 1.0
				for point: Dictionary in expected[ArrangementParent.EAST_ID].own_route_world: point.position[0] = float(point.position[0]) + 1.0
			if not ArrangementExact.exact_equal(derived.rows, expected): return "finite whole-east translation differs or touched another authored value"
			for label: String in ["schema_type", "schema_mix", "unknown", "profile", "canonical_profile", "missing_arrangement", "recipe", "descriptor_extra", "order", "descriptor_profile", "legacy_challenge_recipe", "descriptor_missing_key"]:
				if legacy and label in ["missing_arrangement", "recipe", "descriptor_extra", "order", "descriptor_profile", "legacy_challenge_recipe", "descriptor_missing_key"]: continue
				if label == "legacy_challenge_recipe" and profile != "challenge": continue
				var bad: Dictionary = local.duplicate(true)
				match label:
					"schema_type": bad.schema_version = float(bad.schema_version)
					"schema_mix": bad.schema_version = 2 if legacy else 1
					"unknown": bad["foreign"] = true
					"profile": bad.world.profile_id = "foreign"
					"canonical_profile": bad.scheduler.profile.raw_damage_multiplier += 0.01
					"missing_arrangement": bad.erase("arrangement")
					"recipe": bad.arrangement.recipe_id = "A3-L3/foreign@v1"
					"descriptor_extra": bad.arrangement["east_offset_x"] = 0.1
					"order": bad.arrangement.order.reverse()
					"descriptor_profile": bad.arrangement.profile = "standard" if profile != "standard" else "assisted"
					"legacy_challenge_recipe": bad.arrangement.recipe_id = ArrangementParent.LEGACY_RECIPE_IDS.challenge
					"descriptor_missing_key": bad.arrangement.erase("schema_version")
				var bad_before: Dictionary = bad.duplicate(true)
				var rejected: Dictionary = ArrangementParent.arrangement_constructor(bad, definition)
				if String(rejected.error).is_empty() or not ArrangementExact.exact_equal(bad, bad_before): return "pure malformed control accepted or mutated: " + label
	# A fully rewritten API1 source-free prefix can be valid legacy metadata.
	# Never assert that this pure helper authenticates historical writer provenance.
	return ""

func _pure_selection_unit(profile: String, legacy: bool, selector) -> Dictionary:
	var local: Dictionary = {"api_revision": "act3-mirror-sea-snapshot-1" if legacy else "act3-mirror-sea-snapshot-2", "schema_version": 1 if legacy else 2,
		"world": {"layout_sha256": ArrangementParent.BASE_LAYOUT_SHA256, "encounter_id": ArrangementParent.ENCOUNTER_ID, "world_revision": 1, "profile_id": profile, "collision_fingerprint": {}, "floor_signature": []},
		"scheduler": {"profile": ArrangementDifficulty.new().profile(profile), "encounter_id": ArrangementParent.ENCOUNTER_ID, "world_revision": 1}, "sources": {}, "route": {}, "ring": {}, "view": {}}
	if not legacy: local["arrangement"] = selector.select_fresh(profile)
	return local

## PRIVATE SOURCE-ONLY appendable fragment for mirror_sea_arrangement_smoke.gd.
## Append AFTER genuine old producer seal and arrangement reader promotion.
## Keep producer _run/_open/P3_OLD_PINS as historical originals; dispatch advice
## is in A3_L3_TRANSPORT_INTEGRATION.md. No engine/parser result is implied.
const P3T_Runtime = preload("res://scripts/acts/act3/mirror_sea_level.gd")
const P3T_DEFINITION_PATH: String = "res://data/campaign/act3/a3_l3_difficulty.json"
# Actual OLD producer closed159/0, zero diagnostics, HEAD61b34a7484cb0bb956a183d75804a10cb45ffe25.
# Root retains/seals its original source and raw Store bytes before composition.
const P3T_LEGACY_MANIFEST_SHA256: String = "d8658ace41b461ba2cab78a4016306465774b9b795e6932647301f06b30ddb5f"
const P3T_NEW_KEYS: Array[String] = ["api_revision","schema_version","world","scheduler","sources","route","ring","view","arrangement"]
const P3T_ORDER: Array[String] = ["l3-threshold-stalker","l3-first-echo","l3-useful-west-echo","l3-useful-east-echo","l3-resonant-echo","l3-resonant-pulse","l3-priority-echo","l3-priority-stalker"]
var _p3t_manifest: Dictionary = {}
var _p3t_definition: Dictionary = {}
var _p3t_original_future: Dictionary = {}
var _p3t_bound_level_id: int = 0
var _p3t_current_root: String = ""
var _p3t_current_files: Dictionary = {}
var _p3t_current_samples: Dictionary = {}

func _p3t_defaults() -> bool:
	_test_root = "user://test-a3-l3-arrangement-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_canonical_registry_bytes = FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(P3T_DEFINITION_PATH))
	if not _expect(parsed is Dictionary,"promoted finite arrangement metadata is readable"): return false
	_p3t_definition = parsed.duplicate(true)
	return _expect(P3T_Runtime.arrangement_definition_error(_p3t_definition).is_empty(),"owned pure recipe catalogue is exact before any recipient construction")

func _p3t_read(path: String) -> Dictionary:
	var parsed: Dictionary = ExactJson.parse(FileAccess.get_file_as_string(path))
	if not _expect(parsed.get("accepted") == true and parsed.get("value") is Dictionary,"sealed/current exact native dictionary decodes: "+path): return {}
	return parsed.value

func _p3t_verify_original() -> bool:
	var path: String = P3_ROOT.path_join("manifest.json")
	if not _expect(P3T_LEGACY_MANIFEST_SHA256.length() == 64 and FileAccess.get_sha256(path) == P3T_LEGACY_MANIFEST_SHA256,"Root-reviewed successful OLD producer manifest is required, never inferred from partial files"): return false
	_p3t_manifest = _p3t_read(path)
	if not _expect(_p3t_manifest.get("kind") == "a3-l3-original-challenge-arrangement-legacy-1" and _p3t_manifest.get("files") is Dictionary and _p3t_manifest.get("samples") is Dictionary and _p3t_manifest.samples.has("entrance") and _p3t_manifest.samples.has("first-echo-held") and _p3t_manifest.get("source_pins") is Dictionary,"sealed OLD manifest contains both genuine native sample kinds"): return false
	for source: String in P3_OLD_PINS:
		if not _expect(_p3t_manifest.source_pins.get(source) == P3_OLD_PINS[source],"OLD producer provenance binds original runtime/codec/layout: "+source): return false
	for relative: Variant in _p3t_manifest.files:
		if not _expect(relative is String and not relative.is_absolute_path() and not relative.contains("..") and not relative.contains("://"),"sealed OLD file path is bounded"): return false
		var row: Variant = _p3t_manifest.files[relative]
		var file_path: String = P3_ROOT.path_join(relative)
		if not _expect(row is Dictionary and FileAccess.get_sha256(file_path) == row.get("sha256") and FileAccess.get_file_as_bytes(file_path).size() == row.get("bytes"),"all immutable OLD native/raw Store bytes remain exact: "+relative): return false
	var receipt: Dictionary = _p3t_read(P3_ROOT.path_join("entrance/receipt.json"))
	_p3t_original_future = (receipt.get("future_east_immutable_recipe",{}) as Dictionary).duplicate(true)
	return _expect(not _p3t_original_future.is_empty() and _p3t_original_future.no_live_owner,"OLD source-free entrance retained the canonical future east recipe without constructing its owner")

func _p3t_registry(raw: Dictionary) -> bool:
	_raw_registry = raw.duplicate(true)
	var registry: CinderCampaignRegistry = ProductionRegistry.new(_raw_registry)
	_p3_prefix.assign(registry.main_route().slice(0,12))
	return _expect(registry.last_error.is_empty() and _p3_prefix.size() == 12 and _p3_prefix[-1] == "A3-L2" and registry.entry("A3-L2").scene_path == P3_PREDECESSOR and registry.entry("A3-L3").scene_path == LEVEL_PATH,"actual MAIN L3/TEST predecessor/prefix12 identities remain exact",registry.last_error)

func _p3t_run_legacy() -> bool:
	if not _p3t_defaults() or not _p3t_verify_original() or not _p3t_registry(_p3t_read(P3_ROOT.path_join("registry.native.json"))): return false
	for sample: String in ["entrance","first-echo-held"]:
		var unit: Dictionary = _p3t_read(P3_ROOT.path_join(sample+"/unit.native.json"))
		var session: Dictionary = _p3t_read(P3_ROOT.path_join(sample+"/session.native.json"))
		var checkpoint: Dictionary = _p3t_read(P3_ROOT.path_join(sample+"/checkpoint.native.json"))
		if not _p3t_saved_join(unit,session,checkpoint,sample == "first-echo-held") or not _p3t_stage_original(sample): return false
		if not await _p3t_new_shell(session) or not _p3t_preference("assisted",{}): return false
		_shell.menu.continue_story_requested.emit()
		if not await _p3t_wait_exact(unit,{}) or not _p3t_installed(unit,true) or not await _p3t_quiet(unit,session): return false
		if sample == "first-echo-held":
			var receipt: Dictionary = _p3t_read(P3_ROOT.path_join(sample+"/receipt.json"))
			if not _p3t_warning_equal(receipt.held_warning): return false
		if not await _p3t_retry(checkpoint,session,true) or not await _p3t_close("OLD literal "+sample): return false
		print("Mirror Sea arrangement transport: OLD literal ",sample," exact disk Continue/latest MAIN Retry/retirement passed")
	return _expect(_p3t_verify_original(),"both OLD sample/raw Store banks remain unchanged after opposite-preference MAIN Continue/latest checkpoint Retry")

func _p3t_run_current_persistence() -> bool:
	if not _p3t_defaults() or not _p3t_verify_original(): return false
	# Existing _open creates only a genuine TEST predecessor seed and actual
	# public fresh MAIN Challenge L3. Its OLD pin gate is ONLY in producer _run.
	var error: String = await _open()
	if not _expect(error.is_empty(),"new recipe begins through genuine public predecessor/fresh MAIN Challenge",error): return false
	_p3t_bound_level_id = _level.get_instance_id() # _open already bound once.
	_p3_pins[P3T_DEFINITION_PATH] = FileAccess.get_sha256(P3T_DEFINITION_PATH)
	if not _expect(String(_p3_pins[P3T_DEFINITION_PATH]).length() == 64,"current finite arrangement metadata is pinned with the actual writer sources"): return false
	var entrance: Dictionary = _shell.capture_campaign_snapshot()
	if not _p3t_installed(entrance,false): return false
	var entrance_session: Dictionary = _shell.attempts.state()
	if not _p3t_saved_join(entrance,entrance_session,entrance_session.story.checkpoint,false): return false
	_p3t_current_root = "res://captures/act3/mirror-sea-arrangement/current-held-%d-%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_p3t_current_root)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_p3t_current_root)) == OK,"new actual current archive never overwrites OLD or prior failed data"): return false
	if not _p3t_write("registry.native.json",_raw_registry) or not _p3t_write("start-session.native.json",_p3_seed) or not _p3t_write("source-pins.json",{"source_pins":_p3_pins,"resource_uid_text":_p3_uids}) or not _p3t_archive_current("entrance",entrance,{}): return false
	# Source-free Scheduler1 also takes a REAL new disk recipient, not only the
	# initial live capture. Its saved Challenge selection survives future Assisted.
	var entrance_ids: Dictionary = _p3t_ids()
	if not _p3t_preference("assisted",entrance) or not await _p3t_close("new source-free entrance donor"): return false
	if not await _p3t_new_shell(entrance_session) or not _expect(_shell.get_difficulty_preference() == "assisted","new entrance disk Shell reads opposite future preference"): return false
	_shell.menu.continue_story_requested.emit()
	if not await _p3t_wait_exact(entrance,{}) or not _p3t_distinct(entrance_ids) or not _p3t_installed(entrance,false) or not await _p3t_quiet(entrance,entrance_session): return false
	print("Mirror Sea arrangement transport: new source-free Scheduler1 entrance exact disk Continue/native quiet pair passed")
	_shell.resume_campaign()
	if not _expect(not paused,"public resume starts unchanged native first-two-entry route from authentic restored entrance"): return false
	error = await _travel_entry(0)
	if error.is_empty(): error = _first_source()
	if error.is_empty(): error = await _clear_stalker()
	if error.is_empty(): error = await _travel_entry(1)
	if error.is_empty(): error = _first_echo_ready()
	if error.is_empty(): error = await _unarmed_warning()
	if not _expect(error.is_empty(),"current saved Challenge earns real threshold death/entries and unarmed Echo using unchanged native public controls",error): return false
	if not _expect(_shell.request_pause_deferred(),"current genuine warning accepts public complete-tick pause"): return false
	error = await _p3_wait("pause","A3-L3")
	if not _expect(error.is_empty(),"current genuine warning settles paused without injected tick/clock",error): return false
	var held: Dictionary = _shell.capture_campaign_snapshot()
	var receipt: Dictionary = _p3_held_receipt()
	var saved: Dictionary = _shell.attempts.state()
	var checkpoint: Dictionary = saved.story.checkpoint.duplicate(true)
	if not _p3t_installed(held,false) or not _p3t_saved_join(held,saved,checkpoint,true) or not _expect(not receipt.is_empty(),"current actual native unarmed warning receipt is complete") or not _p3t_archive_current("first-echo-held",held,receipt): return false
	for path: String in _p3_pins:
		if not _expect(FileAccess.get_sha256(path) == _p3_pins[path],"current source/UID pins remain frozen while actual native prefix is earned: "+path): return false
	if not _p3t_write("manifest.json",{"schema_version":1,"kind":"a3-l3-current-east-stone-inset-arrangement-2","test_only":true,"files":_p3t_current_files.duplicate(true),"source_pins":_p3_pins,"resource_uid_text":_p3_uids,"samples":_p3t_current_samples,"legacy_manifest_sha256":P3T_LEGACY_MANIFEST_SHA256,"scope":"Genuine fresh MAIN Challenge entrance/Scheduler1 and first held Echo/Source2/Playback2/Scheduler3/latest CP2; future east recipe X1.65 remains UNINSTALLED. Opposite-preference disk transport/Retry governed by actual runner closure. No east/crossing/full-route/completion/contact or portrait credit."}): return false
	var held_ids: Dictionary = _p3t_ids()
	if not _p3t_preference("assisted",held) or not await _p3t_close("new held warning donor"): return false
	if not await _p3t_new_shell(saved) or not _expect(_shell.get_difficulty_preference() == "assisted","new held disk Shell keeps opposite future preference"): return false
	_shell.menu.continue_story_requested.emit()
	if not await _p3t_wait_exact(held,{}) or not _p3t_distinct(held_ids) or not _p3t_installed(held,false) or not await _p3t_quiet(held,saved) or not _p3t_warning_equal(receipt): return false
	if not await _p3t_retry(checkpoint,saved,false) or not await _p3t_close("new held latest CP2 Retry"): return false
	print("Mirror Sea arrangement transport: new held Scheduler3 warning exact disk Continue/latest MAIN CP2 Retry/retirement passed")
	return _expect(_p3t_verify_original(),"new writer/transport leaves the sealed OLD native/raw Store archive byte-identical")

func _p3t_saved_join(unit: Dictionary, session: Dictionary, checkpoint: Dictionary, held: bool) -> bool:
	if not _expect(not unit.is_empty() and not checkpoint.is_empty() and session.side_attempt == null and session.completed_main == _p3_prefix and session.story.level_id == "A3-L3" and _exact(session.story.snapshot,unit) and _exact(session.story.checkpoint,checkpoint),"actual MAIN complete session/current/protected units join without optional or synthetic history"): return false
	if not held:
		return _expect(_exact(unit,checkpoint) and unit.level.local.scheduler.schema_version == 1 and unit.level.local.scheduler.get("authored_source_cycles",{}).is_empty() and unit.level.local.sources.is_empty() and unit.level.local.route.entries.is_empty() and unit.level.local.route.deaths.is_empty() and unit.player.world_actions.clock_s == 0.0 and unit.player.world_actions.history.is_empty(),"actual source-free entrance has native Scheduler1, no journal/earned history and genuine entrance Retry")
	var ids: Array[String] = ["mirror-sea-shore-entry","mirror-sea-real-body-entry"]
	var expected: Dictionary = {}
	for id: String in ids: expected[id] = "encounter"
	return _expect(unit.level.local.route.entries.size() == 2 and unit.level.local.route.deaths.has(STALKER_ID) and _exact(unit.level.progress.checkpoint_ids,expected) and unit.level.progress.checkpoint_id == ids[1] and _exact(checkpoint.level.progress.checkpoint_ids,expected) and checkpoint.level.progress.checkpoint_id == ids[1] and checkpoint.level.progress.checkpoint_kind == "encounter" and checkpoint.level.local.route.entries.size() == 2 and checkpoint.level.local.route.deaths.has(STALKER_ID),"held current and protected Retry retain actual delivered CP2/death prefix, never entrance policy")

func _p3t_stage_original(sample: String) -> bool:
	if not _expect(not is_instance_valid(_shell),"original Store staging requires no live recipient") or not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_root)) == OK,"isolated raw Store staging directory opens"): return false
	for name: String in ["campaign.json","campaign.json.bak","preferences.json","preferences.json.bak","settings.json","settings.json.bak"]:
		if FileAccess.file_exists(_test_root+name) and not _expect(DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_root+name)) == OK,"remove only prior isolated disposable file: "+name): return false
	for pair: Array in [["campaign.store.json","campaign.json"],["preferences.store.json","preferences.json"],["campaign.store.json.bak","campaign.json.bak"]]:
		if not _p3t_copy(P3_ROOT.path_join(sample+"/"+pair[0]),_test_root+pair[1]): return false
	return true

func _p3t_new_shell(session: Dictionary) -> bool:
	_watch_restore = true
	_quiet_events.clear()
	if not node_added.is_connected(_watch_new_node): node_added.connect(_watch_new_node)
	_shell = ProductionShell.new()
	_game = _shell
	if not _expect(_shell.configure_runtime(_raw_registry,_test_root+"campaign.json",_test_root+"settings.json",_test_root+"preferences.json"),"fresh MAIN Shell configures isolated exact native Store paths"): return false
	root.add_child(_shell)
	var error: String = await _p3_wait("title")
	return _expect(error.is_empty() and _exact(_shell.attempts.state(),session) and _shell.attempts.active_kind() == "story" and not is_instance_valid(_shell.active_level),"actual paused disk startup accepts complete MAIN session before installed Continue",error)

func _p3t_preference(profile: String, unit: Dictionary) -> bool:
	var session: Dictionary = _shell.attempts.state()
	_shell.menu.show_settings()
	var selector: OptionButton = _shell.menu.find_child("DifficultySelector",true,false) as OptionButton
	if not _expect(selector != null,"actual public future difficulty selector exists"): return false
	var index: int = -1
	for i: int in range(selector.item_count):
		if selector.get_item_metadata(i) == profile: index = i
	if not _expect(index >= 0,"canonical opposite future preference exists: "+profile): return false
	selector.select(index)
	selector.item_selected.emit(index)
	var store: CinderSaveStore = ProductionStore.new(_test_root+"preferences.json")
	if not _expect(_shell.get_difficulty_preference() == profile and _exact(store.read_payload(),{"schema_version":1,"profile_id":profile}) and _exact(_shell.attempts.state(),session),"public future preference changes no saved profile/history/session"): return false
	return unit.is_empty() or _expect(_exact(_shell.capture_campaign_snapshot(),unit),"public preference preserves the actual whole native current unit")

func _p3t_wait_exact(unit: Dictionary, previous_ids: Dictionary) -> bool:
	for _frame: int in range(120):
		await process_frame
		if not _expect(is_instance_valid(_shell) and _shell.campaign_error.is_empty(),"public Continue/Retry has no refusal",_shell.campaign_error if is_instance_valid(_shell) else "Shell freed"): return false
		if not paused or _shell.is_pause_requested() or not is_instance_valid(_shell.active_level) or not is_instance_valid(_shell.player) or _shell.menu.page_name() != "resume": continue
		# An old Resume menu/identical packet is not evidence Retry installed.
		if not previous_ids.is_empty() and _shell.world.get_instance_id() == previous_ids.world: continue
		if not _exact(_shell.capture_campaign_snapshot(),unit): continue
		await process_frame
		return _expect(paused and _shell.campaign_error.is_empty() and _exact(_shell.capture_campaign_snapshot(),unit),"actual replacement remains paused/exact after its deferred UI boundary")
	return _expect(false,"exact MAIN replacement exceeded120 process observations",str({"page":_shell.menu.page_name(),"campaign_error":_shell.campaign_error,"checkpoint":unit.level.progress.checkpoint_id}))

func _p3t_installed(unit: Dictionary, legacy: bool) -> bool:
	if not _expect(not unit.is_empty() and paused and is_instance_valid(_shell.active_level),"complete paused installed unit is present"): return false
	_hero = _shell.player
	_level = _shell.active_level
	# Install observers once per real recipient, never rebind the same source.
	if _p3t_bound_level_id != _level.get_instance_id():
		_kit = unit.equipment_ids.duplicate(true)
		_stats = _hero.equipment.resolved_stats()
		_hero_hp = float(unit.player.resources.hp)
		_shells = int(unit.player.resources.shells)
		var bind_error: String = _bind_runtime()
		if not _expect(bind_error.is_empty(),"fresh actual Hero/Scheduler/sources/floor/native context binds",bind_error): return false
		_p3t_bound_level_id = _level.get_instance_id()
	_p3_last_clock = _scheduler.get_clock()
	var local: Dictionary = unit.level.local
	if not _expect(unit.level_id == "A3-L3" and unit.scene_path == LEVEL_PATH and unit.level.local_snapshot_version == 1 and ProductionValue.keys_error(local,P3_KEYS if legacy else P3T_NEW_KEYS).is_empty() and local.api_revision == ("act3-mirror-sea-snapshot-1" if legacy else "act3-mirror-sea-snapshot-2") and typeof(local.schema_version) == TYPE_INT and local.schema_version == (1 if legacy else 2) and local.world.world_revision == 1 and local.world.layout_sha256 == P3_OLD_PINS[P3_LAYOUT] and local.world.profile_id == "challenge" and local.scheduler.api_revision == "scheduler-snapshot-1" and local.scheduler.profile.id == "challenge" and unit.shell.difficulty_at_entry == "challenge","literal OLD8-key/new9-key API/schema and saved Challenge/base-world1 remain exact under opposite preference"): return false
	var selected: Dictionary = P3T_Runtime.arrangement_constructor(local,_p3t_definition)
	var actual: Dictionary = _level.call("mirror_sea_codec_arrangement_state")
	var recipe: String = "A3-L3/challenge-canonical-legacy@v1" if legacy else "A3-L3/challenge-east-stone-inset@v2"
	if not _expect(selected.get("error") == "" and selected.legacy == legacy and actual.get("error") == "" and actual.legacy == legacy and _exact(actual.descriptor,selected.descriptor) and ProductionValue.keys_error(actual.descriptor,["schema_version","profile","recipe_id","order"]).is_empty() and actual.descriptor.profile == "challenge" and actual.descriptor.recipe_id == recipe and _exact(actual.descriptor.order,P3T_ORDER),"one immutable native constructor/retained recipe selection precedes whole source validation",str(actual)): return false
	if not legacy and not _expect(_exact(local.arrangement,actual.descriptor),"new writer persists its exact closed selected arrangement"): return false
	var future: Dictionary = _p3t_original_future.duplicate(true)
	if not legacy:
		future.translation_x = Vector3(1.65,0,0).x
		for point: Dictionary in future.route: point.position = ProductionValue.vector3(ProductionValue.read_vector3(point.position)+Vector3.RIGHT)
		future.slash_origin = ProductionValue.vector3(ProductionValue.read_vector3(future.slash_origin)+Vector3.RIGHT)
	if not _expect(_exact(_p3_future_east(),future) and not (_level.get("sources") as Dictionary).has("l3-useful-east-echo"),"uninstalled future east retains the complete saved recipe/canonical X0.65 or changed X1.65; no earned east history"): return false
	var entries: int = local.route.entries.size()
	if entries == 0:
		if not _expect(local.scheduler.schema_version == 1 and local.scheduler.get("authored_source_cycles",{}).is_empty() and local.sources.is_empty() and local.scheduler.reservations.is_empty(),"native arrival remains Scheduler1/no authored journal or owner"): return false
	elif entries == 2:
		var journal: Variant = local.scheduler.get("authored_source_cycles")
		if not _expect(ProductionValue.keys_error(local.sources,[STALKER_ID,ECHO_ID]).is_empty() and local.sources[STALKER_ID].kind == "stalker" and local.sources[STALKER_ID].actor.dead and local.sources[STALKER_ID].actor.hp == 0.0 and local.route.deaths.has(STALKER_ID) and local.scheduler.schema_version == 3 and journal is Dictionary and journal.get("sources") is Array and journal.sources.size() == 1 and journal.sources[0] is Dictionary and journal.sources[0].source_id == ECHO_ID and local.sources[ECHO_ID].kind == "echo" and local.sources[ECHO_ID].actor.api_revision == "act3-mirror-echo-source-2" and local.sources[ECHO_ID].actor.generation == 1 and local.sources[ECHO_ID].actor.alive and local.sources[ECHO_ID].actor.hp == 36.0 and local.sources[ECHO_ID].actor.source_hits == 0,"native earned prefix retains real Stalker tombstone and complete Source2/Playback2/Scheduler3 journal"): return false
	else: return _expect(false,"early transport grants no other court/earned history")
	var error: String = _pair_error({"hero":unit.player,"level":unit.level})
	if not _expect(error.is_empty() and _exact(_shell.capture_campaign_snapshot(),unit),"complete native paired validation/ExactJSON/recapture remains authoritative",error): return false
	var view: Dictionary = _level.call("camera_framing_union","",[],true,false)
	error = String(view.get("error","Actual current native union unavailable"))
	var actual_points: Array = view.points.duplicate() if error.is_empty() else []
	# A source-free entrance has no source bounds. Supply the actual Hero's
	# native corners to this shared nonempty context API; held cases retain
	# the complete source union and cannot substitute player-only geometry.
	if error.is_empty() and entries == 0:
		actual_points.append_array(_shell.player_camera_framing_points_for(_hero,_shell.camera))
	if error.is_empty(): error = _shell.camera_framing_error_for_context(actual_points,_hero,_shell.camera,_shell.hud)
	return _expect(error.is_empty() and _shell.camera == _hero.get_viewport().get_camera_3d() and _shell.camera.get_world_3d() == _hero.get_world_3d() and _exact(_shell.capture_campaign_snapshot(),unit),"actual current Camera/HUD/native union and full recapture retain saved optics",error)

func _p3t_warning_equal(saved_receipt: Dictionary) -> bool:
	var actual: Dictionary = _p3_held_receipt()
	var expected: Dictionary = saved_receipt.duplicate(true)
	actual.erase("actual_source_instance_id_decimal_text")
	expected.erase("actual_source_instance_id_decimal_text")
	return _expect(not actual.is_empty() and _exact(actual,expected),"fresh actual warning retains original source/epoch/generation/program lease/deadlines/clock without arming or repair")

func _p3t_ids() -> Dictionary:
	var level: CinderLevel = _shell.active_level
	var scheduler: Node = level.get("threat_scheduler") as Node
	var bindings: Dictionary = level.call("scheduler_bindings")
	var floor: Node = (bindings.floors["firm-shore"] as Dictionary).collision as Node
	var ids: Dictionary = {"world":_shell.world.get_instance_id(),"world3d":_shell.world.get_world_3d().get_instance_id(),"level":level.get_instance_id(),"hero":_shell.player.get_instance_id(),"scheduler":scheduler.get_instance_id(),"camera":_shell.camera.get_instance_id(),"floor":floor.get_instance_id()}
	for id: String in (level.get("sources") as Dictionary): ids[id] = ((level.get("sources") as Dictionary)[id] as Node).get_instance_id()
	return ids

func _p3t_distinct(previous: Dictionary) -> bool:
	var actual: Dictionary = _p3t_ids()
	if not _expect(not previous.is_empty() and not actual.is_empty(),"real complete donor and recipient native identity maps are required"): return false
	for key: String in previous:
		if not _expect(actual.has(key) and actual[key] != previous[key],"fresh native recipient identity differs: "+key): return false
	return true

func _p3t_retry(checkpoint: Dictionary, before_session: Dictionary, legacy: bool) -> bool:
	var ids: Dictionary = _p3t_ids()
	var refs: Array[WeakRef] = []
	var container: Node = _shell.world.get_parent().get_parent()
	if not _expect(container is SubViewportContainer and container.get_parent() == _shell,"Retry observes the complete actual old prepared viewport subtree"): return false
	_p3_collect(container,refs)
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	_detach_quiet_observers() # Only test listeners; real donor retirement is allowed.
	_quiet_events.clear()
	_watch_restore = true
	_shell.request_retry()
	if not await _p3t_wait_exact(checkpoint,ids) or not _p3t_distinct(ids) or not await _p3t_released(refs,"Retry donor viewport"): return false
	if is_instance_valid(_barrier): _barrier.queue_free()
	if not _p3t_installed(checkpoint,legacy): return false
	var expected: Dictionary = before_session.duplicate(true)
	expected.story.snapshot = checkpoint.duplicate(true)
	if not _expect(_exact(_shell.attempts.state(),expected) and _exact(expected.story.checkpoint,checkpoint) and _exact(events,_events) and _exact(actions,_actions),"actual latest MAIN Retry replaces only current snapshot and preserves full protected/session/progression/action prefix"): return false
	if not await _p3t_quiet(checkpoint,expected): return false
	var disk_error: String = _disk_error(expected)
	return _expect(disk_error.is_empty(),"Retry independent primary Store equals the whole exact MAIN session",disk_error)

func _p3t_quiet(unit: Dictionary, session: Dictionary) -> bool:
	if not _expect(_quiet_events.is_empty(),"fresh native construction/quiet restore emits no gameplay callbacks",str(_quiet_events)): return false
	var before: Dictionary = {"input":_shell.get_input_observation_state(),"events":_events.duplicate(true),"actions":_actions.duplicate(true),"quiet":_quiet_events.duplicate(),"ids":_p3t_ids(),"camera":_camera_packet(),"signals":_quiet_signal_flags()}
	if not _expect(not before.ids.is_empty(),"quiet witness contains real complete native identity map"): return false
	for _frame: int in range(3): await process_frame
	return _expect(paused and _shell.campaign_error.is_empty() and _exact(_shell.capture_campaign_snapshot(),unit) and _exact(_shell.attempts.state(),session) and _exact(_shell.get_input_observation_state(),before.input) and _exact(_events,before.events) and _exact(_actions,before.actions) and _exact(_quiet_events,before.quiet) and _exact(_p3t_ids(),before.ids) and _exact(_camera_packet(),before.camera) and _exact(_quiet_signal_flags(),before.signals) and _disk_error(session).is_empty(),"paused whole native/current input/Camera fields/signal flags/clocks/resources/history/session/disk remain exact across actual process boundaries; HUD binding/containment checked separately")

func _p3t_released(refs: Array[WeakRef], label: String) -> bool:
	for _frame: int in range(120):
		var freed: bool = true
		for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
		if freed: return _expect(true,label+": every actual native subtree node is freed")
		await process_frame
	return _expect(false,label+": retained native node remains after bounded120 observations")

func _p3t_close(label: String) -> bool:
	if not is_instance_valid(_shell): return true
	_watch_restore = false
	_detach_quiet_observers()
	var refs: Array[WeakRef] = []
	_p3_collect(_shell,refs)
	if is_instance_valid(_shell.active_level):
		var scheduler: CinderThreatScheduler = _shell.active_level.get("threat_scheduler") as CinderThreatScheduler
		var bindings: Dictionary = _shell.active_level.call("scheduler_bindings")
		var clock: float = scheduler.get_clock()
		var actor_clock: float = _shell.player.get_world_action_clock()
		var actions: Array[Dictionary] = _shell.player.get_world_action_records()
		var resources: Dictionary = {"hp":_shell.player.hp,"shells":_shell.player.shells,"dead":_shell.player.dead}
		_shell.active_level.exit_level()
		var retired: bool = scheduler.is_inside_tree() and _shell.player.is_inside_tree() and scheduler.get_clock() == clock and _shell.player.get_world_action_clock() == actor_clock and _exact(actions,_shell.player.get_world_action_records()) and _exact(resources,{"hp":_shell.player.hp,"shells":_shell.player.shells,"dead":_shell.player.dead})
		for owner: Node3D in bindings.owners.values():
			var control: Dictionary = scheduler.source_control_state(owner)
			retired = retired and not control.is_empty() and control.get("outside_transaction",false) and control.get("reservations",[]).is_empty() and control.clock_s == clock
		if not _expect(retired,label+": actual inside-tree public exit releases native owners without clock/resource/history reset"): return false
	_shell.queue_free()
	_shell = null
	_game = null
	_hero = null
	_level = null
	_scheduler = null
	_stalker = null
	_echo = null
	_barrier = null
	_p3t_bound_level_id = 0
	_quiet_targets.clear()
	if not await _p3t_released(refs,label): return false
	return _expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),label+": no native enemy/cue group residue")

func _p3t_copy(source: String, target: String) -> bool:
	var sha: String = FileAccess.get_sha256(source)
	return _expect(sha.length() == 64 and not FileAccess.file_exists(target) and DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(target)) == OK and FileAccess.get_sha256(source) == sha and FileAccess.get_sha256(target) == sha,"actual raw format2 bytes copy unchanged: "+source)

func _p3t_write(relative: String, value: Dictionary) -> bool:
	var wire: String = ExactJson.stringify(value)
	var target: String = _p3t_current_root.path_join(relative)
	if not _expect(not wire.is_empty() and not FileAccess.file_exists(target),"new finite exact current provenance file only: "+relative): return false
	var file: FileAccess = FileAccess.open(target,FileAccess.WRITE)
	if not _expect(file != null,"current provenance file opens: "+relative): return false
	file.store_string(wire+"\n"); file.flush()
	var error: Error = file.get_error()
	file.close()
	if not _expect(error == OK and FileAccess.get_file_as_string(target) == wire+"\n","actual exact current provenance bytes persist: "+relative): return false
	_p3t_current_files[relative] = {"sha256":FileAccess.get_sha256(target),"bytes":FileAccess.get_file_as_bytes(target).size(),"exact_wire_sha256":wire.sha256_text()}
	return true

func _p3t_archive_current(label: String, unit: Dictionary, receipt: Dictionary) -> bool:
	var session: Dictionary = _shell.attempts.state()
	if not _p3t_saved_join(unit,session,session.story.checkpoint,label == "first-echo-held") or not _expect(_disk_error(session).is_empty(),"current native primary Store independently equals actual complete MAIN session",_disk_error(session)): return false
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_p3t_current_root.path_join(label))) == OK,"new current sample folder opens"): return false
	if not _p3t_write(label+"/unit.native.json",unit) or not _p3t_write(label+"/session.native.json",session) or not _p3t_write(label+"/checkpoint.native.json",session.story.checkpoint) or not _p3t_write(label+"/receipt.json",{"schema_version":1,"test_only":true,"sample":label,"held_warning":receipt,"future_east_immutable_recipe":_p3_future_east(),"actual_native_ids_decimal_text":_p3t_id_text()}): return false
	for pair: Array in [["campaign.json","campaign.store.json"],["preferences.json","preferences.store.json"],["campaign.json.bak","campaign.store.json.bak"]]:
		var relative: String = label+"/"+pair[1]
		var target: String = _p3t_current_root.path_join(relative)
		if not _p3t_copy(_test_root+pair[0],target): return false
		_p3t_current_files[relative] = {"sha256":FileAccess.get_sha256(target),"bytes":FileAccess.get_file_as_bytes(target).size(),"raw_store_copy":true,"original_user_path":_test_root+pair[0]}
	_p3t_current_samples[label] = {"unit":label+"/unit.native.json","session":label+"/session.native.json","checkpoint":label+"/checkpoint.native.json","receipt":label+"/receipt.json"}
	return _expect(_exact(_shell.capture_campaign_snapshot(),unit) and _exact(_shell.attempts.state(),session),"archival writes preserve actual native unit/session: "+label)

func _p3t_id_text() -> Dictionary:
	var result: Dictionary = {}
	var ids: Dictionary = _p3t_ids()
	for key: String in ids: result[key] = str(ids[key])
	return result

## APPEND/merge into Root's new focused test extending production_warning_smoke.
## _tick dispatch must be merged with any producer override, not duplicated.
signal ec_component_disposed
const EC_Runtime = preload("res://scripts/acts/act3/mirror_sea_level.gd")
const EC_Component = preload("res://tests/acts/act3/fixtures/a3_l3_arrangement/east_component.gd")
const EC_START: Vector3 = Vector3(0.65, 0.1, -1.7)
const EC_ID: String = "l3-useful-east-echo"
const EC_SLOTS: Array[String] = ["jacket", "pants", "shoes", "weapon"]
var _ec_running: bool = false
var _ec_disposing: bool = false
var _ec_dispose_result: String = ""
var _ec_stopping: bool = false
var _ec_ticks: int = 0
var _ec_start_hp: float = 0.0
var _ec_seen: Dictionary = {}
var _ec_hit_count: int = 0
var _ec_contact_count: int = 0
var _ec_forbidden: Array[String] = []
var _ec_lease: Dictionary = {}
var _ec_scene_handles: Array[PackedScene] = []
var _ec_native_handles: Array[Node] = []
var _ec_declines: Array[Dictionary] = []
var _ec_results: Array[Dictionary] = []
var _ec_quiet: Array[String] = []

func _ec_run(selector: String, portrait_writer: Callable = Callable()) -> Dictionary:
	if selector not in ["--east-component", "--east-component-portrait"]: return {"error": "Unknown declared east component selector"}
	if is_instance_valid(_game) or is_instance_valid(_shell): return {"error": "Component cannot borrow a producer/Shell"}
	if EC_Runtime.API != "act3-mirror-sea-parent-2": return {"error": "Component waits for separately approved reader promotion and real old-writer seal"}
	_ec_running = true
	_ec_results.clear()
	var choices: Array[Dictionary] = [{"label": "canonical-challenge-baseline", "changed": false, "combined": false}, {"label": "changed-challenge-baseline", "changed": true, "combined": false}]
	if selector == "--east-component-portrait": choices = [{"label": "changed-challenge-portrait", "changed": true, "combined": false}]
	for choice: Dictionary in choices:
		var result: Dictionary = await _ec_case(choice, portrait_writer if selector == "--east-component-portrait" else Callable())
		_ec_results.append(result)
		var cleanup: String = await _ec_dispose_all()
		if not cleanup.is_empty(): return {"error": cleanup, "cases": _ec_results, "component_only": true}
		if not String(result.get("error", "Missing actual case result")).is_empty(): return {"error": String(result.error), "cases": _ec_results, "component_only": true}
	if selector == "--east-component-portrait": return {"error": "", "cases": _ec_results, "component_only": true, "parent_route_or_save_credit": false}
	var first: Dictionary = _ec_results[0]
	var second: Dictionary = _ec_results[1]
	var different_return: bool = (first.primary_origin as Vector3).distance_to(second.primary_origin) > POINT_TOLERANCE
	var different_path: bool = not _exact(first.executed_landings, second.executed_landings)
	var useful_difference: bool = different_return and different_path
	if not useful_difference: return {"error": "", "outcome": "no_useful_difference", "needs_integration_refinement": true, "cases": _ec_results.duplicate(true), "parent_route_or_save_credit": false}
	var combined: Dictionary = await _ec_case({"label": "changed-challenge-combined-short-slow", "changed": true, "combined": true}, Callable())
	_ec_results.append(combined)
	var cleanup: String = await _ec_dispose_all()
	return {"error": cleanup if not cleanup.is_empty() else String(combined.get("error", "Missing combined result")), "outcome": "observed_different_native_response", "cases": _ec_results.duplicate(true), "human_balance_credit": false, "parent_route_or_save_credit": false}

func _ec_make_scene(changed: bool, restore_only: bool) -> Dictionary:
	var template: Node3D = load(LEVEL_PATH).instantiate()
	var declared: CinderLevel = EC_Component.new()
	declared.name = "TEST_EastEchoComponent"
	declared.level_id = "A3-L3"; declared.set("ece_changed", changed); declared.set("ece_restore_only", restore_only)
	for child: Node in template.get_children():
		var copy: Node = child.duplicate()
		declared.add_child(copy); _ec_assign_owner(copy, declared)
	template.free()
	(declared.get_node(declared.spawn_path) as Marker3D).position = EC_START
	var scene := PackedScene.new()
	var error: Error = scene.pack(declared)
	declared.free()
	if error != OK: return {"error": "Declared east component packing failed"}
	var path: String = "res://tests/acts/act3/__TEST_east_component_%d_%d.tscn" % [OS.get_process_id(), Time.get_ticks_usec()]
	if FileAccess.file_exists(path) or ResourceLoader.has_cached(path): return {"error": "Unique TEST component scene cache path unavailable"}
	scene.take_over_path(path); _ec_scene_handles.append(scene)
	return {"error": "", "scene": scene, "path": path}

func _ec_assign_owner(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child: Node in node.get_children(): _ec_assign_owner(child, owner_node)

func _ec_spawn(changed: bool, combined: bool, restore_only: bool) -> Dictionary:
	if _p3_done: return {"error": "Component finalizer owns shutdown; no new native construction"}
	var main: Node = MainScene.instantiate()
	_ec_native_handles.append(main)
	root.add_child(main)
	main.call("open_bench")
	var lab: CinderPlayer = main.get("player") as CinderPlayer
	var kit: Dictionary = {"jacket": "CLOTH-J0", "pants": "CLOTH-P2" if combined else "CLOTH-P0", "shoes": "CLOTH-S2" if combined else "CLOTH-S0", "weapon": "WEAPON-03" if combined else "WEAPON-01"}
	if lab == null or not paused: return {"error": "Actual paused Lab required for public initial equipment selection"}
	for slot: String in EC_SLOTS:
		if not lab.equip_item(String(kit[slot])): return {"error": "Public initial equipment refused: " + slot}
	var packed: Dictionary = _ec_make_scene(changed, restore_only)
	if not String(packed.error).is_empty(): return packed
	if not main.call("load_level_scene", packed.path): return {"error": "Public fresh component load refused: " + String(main.get("level_load_error"))}
	main.call("open_bench")
	var hero: CinderPlayer = main.get("player") as CinderPlayer
	var level: CinderLevel = main.get("active_level") as CinderLevel
	if hero == null or hero == lab or level == null or level.get_script() != EC_Component: return {"error": "Fresh declared component/Hero bindings unavailable"}
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	var source: Node3D = (level.get("sources") as Dictionary).get(EC_ID) as Node3D
	if scheduler == null or source == null or not String(level.call("runtime_error")).is_empty(): return {"error": "Actual component native construction refused: " + String(level.get("last_configuration_error"))}
	if not paused or hero.global_position != EC_START or hero.hp != hero.max_hp or hero.get_world_action_clock() != 0.0 or scheduler.get_clock() != 0.0 or scheduler.encounter_profile().id != "challenge" or not _exact(hero.equipment.snapshot(), kit) or float(source.get("hp")) != 36.0 or source.call("source_cycles_managed") == restore_only: return {"error": "Declared full-HP/clock0/Challenge/native configuration differs"}
	var actual: Dictionary = level.call("state")
	if not actual.route.entries.is_empty() or not actual.route.deaths.is_empty() or not actual.route.pending_checkpoint_boundaries.is_empty() or actual.completed or actual.exit_state != "clear" or not actual.contact.is_empty() or (level.get("sources") as Dictionary).size() != 1 or is_instance_valid(level.get("mechanism")): return {"error": "Declared component acquired canonical parent prefix/progress"}
	if not level.snapshot_state().is_empty() or level.last_snapshot_error != EC_Component.ECE_SAVE_LIMIT: return {"error": "Component must refuse canonical parent save authority"}
	return {"error": "", "main": main, "hero": hero, "level": level, "scheduler": scheduler, "source": source, "kit": kit, "world": hero.get_world_3d()}

func _ec_case(choice: Dictionary, portrait_writer: Callable) -> Dictionary:
	if _p3_done: return {"error": "Component finalizer owns shutdown; no new native construction"}
	_ec_running = true; _ec_stopping = false
	_ec_ticks = 0; _ec_seen.clear(); _ec_hit_count = 0; _ec_contact_count = 0; _ec_forbidden.clear(); _ec_declines.clear(); _ec_lease.clear()
	_actions.clear(); _events.clear(); _held_source = ""; _held_record = {}; _commit_observation_enabled = false
	root.size = Vector2i(340, 736); root.content_scale_size = root.size; root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var opened: Dictionary = _ec_spawn(choice.changed, choice.combined, false)
	if not String(opened.error).is_empty(): return opened
	_game = opened.main; _hero = opened.hero; _level = opened.level; _scheduler = opened.scheduler; _echo = opened.source; _stalker = null
	_kit = opened.kit; _stats = _hero.equipment.resolved_stats(); _hero_hp = _hero.hp; _shells = _hero.shells; _ec_start_hp = _hero.hp
	_barrier = PostActorBarrier.new(); _barrier.name = "TEST_EastComponentPostActor"; _game.add_child(_barrier)
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.equipment_changed.connect(func(_id: String) -> void: _ec_forbidden.append("equipment"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _ec_forbidden.append("checkpoint"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _ec_forbidden.append("completion"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _ec_forbidden.append("exit"))
	_echo.connect("source_hit_resolved", func(_receipt: Dictionary) -> void: _ec_hit_count += 1)
	_echo.connect("event_dispatched", func(_event_data: Dictionary, receipt: Dictionary) -> void:
		if receipt.get("contact", false) or receipt.get("damage_attempted", false): _ec_contact_count += 1
	)
	_game.call("resume_lab")
	var error: String = ""
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		if (_echo.call("state") as Dictionary).status == "running": break
		error = await _ec_tick()
		if not error.is_empty(): return {"error": error, "native_refusals": _ec_declines.duplicate(true)}
	if (_echo.call("state") as Dictionary).status != "running": return {"error": "Bounded ordinary native admission refused", "native_refusals": _ec_declines.duplicate(true)}
	var warning: Dictionary = (_level.call("state") as Dictionary).echo_records[EC_ID].duplicate(true)
	if _echo.call("source_phase") != "warning": return {"error": "Initial actual warning was skipped"}
	_ec_seen["warning"] = true
	if choice.label == "changed-challenge-portrait":
		_game.call("open_bench")
		if not portrait_writer.is_valid(): return {"error": "Portrait adapter remains unexecuted/unsupplied"}
		var portrait: Dictionary = await portrait_writer.call(_game, _level, _hero, _scheduler, warning)
		return {"error": String(portrait.get("error", "Missing actual portrait result")), "portrait": portrait, "component_only": true}
	# Save actual warning packets only as component transport; parent save refuses.
	_game.call("open_bench")
	var pair: Dictionary = _level.call("ece_native_pair")
	if pair.is_empty(): return {"error": "Actual native warning component pair unavailable"}
	if choice.changed and not choice.combined:
		error = await _ec_transport(pair, opened)
		if not error.is_empty(): return {"error": error, "component_only": true}
	_game.call("resume_lab")
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		var state: Dictionary = _level.call("state")
		if state.echo_records[EC_ID].locked: break
		if (_echo.call("state") as Dictionary).status != "running": return {"error": "Actual warning safely cancelled before lock", "reason": _level.get("last_admission_reason")}
		error = await _ec_tick()
		if not error.is_empty(): return {"error": error}
	var actual: Dictionary = _level.call("state")
	if not actual.echo_records[EC_ID].locked: return {"error": "Actual due observer did not lock within bounded wait"}
	_ec_lease = _scheduler.replay_reservation_state(String(actual.echo_records[EC_ID].lease.id))
	var proof: Dictionary = actual.echo_records[EC_ID].proof.duplicate(true)
	error = await _follow(proof, EC_ID) # Existing public swipe/tap/physical proof checks.
	if not error.is_empty(): return {"error": error, "native_refusals": _ec_declines.duplicate(true)}
	var primaries: Array[Dictionary] = []
	var landings: Array[Vector3] = []
	for action: Dictionary in _actions:
		if action.kind == "primary": primaries.append(action)
		if action.kind == "dash": landings.append(action.landing)
	if primaries.size() != 1 or _ec_hit_count != 1 or _ec_contact_count != 0 or _hero.hp != _ec_start_hp: return {"error": "One genuine ordinary primary/full Hero HP/no masked contact contract failed"}
	for phase: String in ["warning", "lock", "active", "recovery"]:
		if not _ec_seen.has(phase): return {"error": "Actual native phase witness missing: " + phase}
	return {"error": "", "label": choice.label, "changed": choice.changed, "initial_position": EC_START, "profile": "challenge", "kit": _kit.duplicate(true), "definition": _echo.call("source_definition"), "accepted_proof": proof, "executed_landings": landings, "primary_origin": primaries[0].world_origin, "primary": primaries[0], "hero_hp": _hero.hp, "source_hp": _echo.get("hp"), "native_ticks": _ec_ticks, "native_refusals": _ec_declines.duplicate(true), "parent_route_or_save_credit": false}

func _ec_tick() -> String:
	if paused or not is_instance_valid(_barrier): return "Actual component cannot tick paused/unbound tree"
	_barrier.waiting = true
	await _barrier.observed
	if _ec_stopping: return "Component retiring; no native observation credit"
	_ec_ticks += 1
	if paused: return "Unexpected actual component pause"
	var error: String = String(_level.call("runtime_error"))
	if not error.is_empty(): return error
	if _hero.dead or _hero.hp != _ec_start_hp or not _exact(_hero.equipment.snapshot(), _kit) or not _exact(_hero.equipment.resolved_stats(), _stats) or not _ec_forbidden.is_empty() or _ec_contact_count != 0 or _events.get("fired_blast", 0) != 0: return "Native component HP/kit/ordinary/no-progress invariant changed"
	if _scheduler.get_clock() > 30.0 or absf(_hero.get_world_action_clock() - _scheduler.get_clock()) > TIME_EPSILON: return "Bounded actual component clock/join changed"
	var state: Dictionary = _level.call("state")
	if not state.route.entries.is_empty() or not state.route.deaths.is_empty() or not state.route.pending_checkpoint_boundaries.is_empty() or state.completed or not state.contact.is_empty(): return "TEST component earned forbidden canonical progress"
	if not _frontier_floor_hit(_hero.global_position) or not String(_echo.call("source_native_error")).is_empty(): return "Actual component floor/native source custody failed"
	var phase: String = String(_echo.call("source_phase")); _ec_seen[phase] = true
	if not _ec_lease.is_empty():
		var lease: Dictionary = _scheduler.replay_reservation_state(String(_ec_lease.id))
		if lease.is_empty() or lease.source_instance_id != _echo.get_instance_id(): return "Actual held source identity/lease changed"
		for key: String in FIXED_DEADLINES:
			if not _exact(lease[key], _ec_lease[key]): return "Actual locked deadline changed: " + key
	var decline: String = String(_level.get("last_admission_reason"))
	if not decline.is_empty() and (_ec_declines.is_empty() or _ec_declines.back().reason != decline): _ec_declines.append({"clock_s": _scheduler.get_clock(), "reason": decline})
	return ""

func _ec_transport(pair: Dictionary, donor: Dictionary) -> String:
	if not paused or pair.is_empty(): return "Actual paused source/Playback/Scheduler/Player component packets required"
	var wire: String = ExactJson.stringify(pair)
	var decoded: Dictionary = ExactJson.parse(wire)
	if wire.is_empty() or not decoded.get("accepted", false) or not _exact(pair, decoded.value): return "Component native ExactJSON lost typed values/binary64 bits"
	var donor_observation: Dictionary = _ec_context_observation(donor)
	if donor_observation.is_empty() or not donor_observation.get("native_pair") is Dictionary or donor_observation.native_pair.is_empty(): return "Nonempty donor native pair/context required before encoding"
	for key: String in ["player", "source", "scheduler", "playback"]:
		if not donor_observation.native_pair.get(key) is Dictionary or donor_observation.native_pair[key].is_empty(): return "Complete nonempty donor native field required: " + key
	var donor_before: PackedByteArray = var_to_bytes(donor_observation)
	if donor_before.is_empty(): return "Nonempty typed donor witness required"
	var wrong: Dictionary = _ec_spawn(false, false, true)
	if not String(wrong.error).is_empty(): return String(wrong.error)
	if wrong.world == donor.world or wrong.main == donor.main or wrong.source == donor.source: return "Cross-recipe recipient is not an independent actual world/source"
	_ec_quiet.clear(); _ec_watch_quiet(wrong)
	var wrong_before: PackedByteArray = var_to_bytes(_ec_untracked_observation(wrong))
	var rejected: String = String(wrong.level.call("ece_prepare_pair", decoded.value))
	if rejected.is_empty() or not _ec_quiet.is_empty() or wrong_before != var_to_bytes(_ec_untracked_observation(wrong)) or donor_before != var_to_bytes(_ec_context_observation(donor)): return "Wrong canonical recipe accepted/mutated native state or donor"
	if not rejected.contains("Actual source/definition/cycle/profile/world binding differs"): return "Cross-recipe refusal has an unrelated cause, no geometry rejection credit: " + rejected
	print("EAST COMPONENT CROSS-RECIPE REJECT: ", rejected)
	var cleanup: String = await _ec_dispose_one(wrong)
	if not cleanup.is_empty(): return cleanup
	var fresh: Dictionary = _ec_spawn(true, false, true)
	if not String(fresh.error).is_empty(): return String(fresh.error)
	if fresh.world == donor.world or fresh.main == donor.main or fresh.hero == donor.hero or fresh.source == donor.source or fresh.scheduler == donor.scheduler: return "Native component transport reused donor identities/world"
	_ec_quiet.clear(); _ec_watch_quiet(fresh)
	var error: String = String(fresh.level.call("ece_prepare_pair", decoded.value))
	if error.is_empty(): error = String(fresh.level.call("ece_commit_pair", decoded.value))
	if not error.is_empty(): return "Actual strict distinct-world component restore refused: " + error
	var actual: Dictionary = fresh.level.call("ece_native_pair")
	if actual.is_empty() or not _exact(actual, pair) or not _ec_quiet.is_empty() or not paused or donor_before != var_to_bytes(_ec_context_observation(donor)): return "Quiet distinct-world native transport changed complete packets/events/donor"
	if not fresh.level.snapshot_state().is_empty() or fresh.level.last_snapshot_error != EC_Component.ECE_SAVE_LIMIT: return "Native component transport acquired parent save authority"
	print("EAST COMPONENT NATIVE TRANSPORT: exact actual Player/source/Scheduler/Playback, distinct native world and identities; no parent/save/route authority")
	return await _ec_dispose_one(fresh)

func _ec_context_observation(handle: Dictionary) -> Dictionary:
	var pair: Dictionary = handle.level.call("ece_native_pair")
	if pair.is_empty(): return {}
	return {"native_pair": pair, "actions": handle.hero.get_world_action_records(), "input": handle.main.call("get_input_observation_state"), "hero_transform": handle.hero.global_transform, "source_transform": handle.source.global_transform, "camera": _ec_camera(handle.main), "component": handle.level.call("state")}

func _ec_untracked_observation(handle: Dictionary) -> Dictionary:
	var source_state: Dictionary = handle.source.call("get_source_state")
	source_state.erase("snapshot_error") # Diagnostic error text is not native state.
	return {"player": handle.hero.snapshot_state(), "actions": handle.hero.get_world_action_records(), "source": source_state, "program": handle.source.call("source_program"), "native": handle.source.call("native_descriptor"), "playback": handle.source.call("state"), "scheduler": handle.scheduler.snapshot_state(handle.level.call("scheduler_bindings")), "recipe": handle.source.call("get_authored_cycle_restore_recipe"), "transform": handle.source.global_transform, "camera": _ec_camera(handle.main)}

func _ec_camera(main: Node) -> Array:
	var camera: Camera3D = main.get("camera") as Camera3D
	return [] if camera == null else [camera.global_transform, camera.projection, camera.keep_aspect, camera.size, camera.near, camera.far, camera.h_offset, camera.v_offset, camera.frustum_offset, camera.cull_mask]

func _ec_watch_quiet(handle: Dictionary) -> void:
	var actor: Node = handle.source
	actor.connect("state_changed", func(_value: Dictionary) -> void: _ec_quiet.append("source_state"))
	actor.connect("source_hit_resolved", func(_value: Dictionary) -> void: _ec_quiet.append("source_hit"))
	actor.connect("source_defeated", func(_value: Dictionary) -> void: _ec_quiet.append("source_defeated"))
	actor.connect("died", func() -> void: _ec_quiet.append("source_died"))
	actor.connect("event_dispatched", func(_event_data: Dictionary, _receipt: Dictionary) -> void: _ec_quiet.append("source_event"))
	handle.hero.world_action_executed.connect(func(_value: Dictionary) -> void: _ec_quiet.append("player_action"))
	handle.hero.fired.connect(func(_kind: String) -> void: _ec_quiet.append("player_fired"))
	handle.hero.died.connect(func() -> void: _ec_quiet.append("player_died"))
	handle.hero.equipment_changed.connect(func(_id: String) -> void: _ec_quiet.append("player_equipment"))
	handle.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _ec_quiet.append("invalidated"))

func _ec_dispose_one(handle: Dictionary) -> String:
	var refs: Array[WeakRef] = []
	for key: String in ["main", "hero", "level", "scheduler", "source"]:
		if is_instance_valid(handle.get(key)): refs.append(weakref(handle[key]))
	var clock: float = handle.scheduler.get_clock() if is_instance_valid(handle.get("scheduler")) else -1.0
	var actor_clock: float = handle.hero.get_world_action_clock() if is_instance_valid(handle.get("hero")) else -1.0
	var retirement_error: String = ""
	if is_instance_valid(handle.get("level")): handle.level.exit_level()
	if is_instance_valid(handle.get("scheduler")) and is_instance_valid(handle.get("source")):
		var control: Dictionary = handle.scheduler.source_control_state(handle.source)
		if control.is_empty() or not control.reservations.is_empty() or handle.scheduler.get_clock() != clock or handle.hero.get_world_action_clock() != actor_clock: retirement_error = "Actual component whole-world retirement failed or advanced native clock"
	if is_instance_valid(handle.get("main")):
		var effects: PixelEffects = handle.main.get("fx") as PixelEffects
		if effects != null: effects.clear_lab()
		handle.main.queue_free()
	for _i: int in range(120):
		await process_frame
		var freed: bool = true
		for ref: WeakRef in refs:
			if ref.get_ref() != null: freed = false
		if freed: return retirement_error
	return "Native component whole-world references survived bounded normal disposal"

func _ec_dispose_all() -> String:
	if _ec_disposing:
		await ec_component_disposed
		return _ec_dispose_result
	_ec_disposing = true
	_ec_stopping = true
	paused = true
	if is_instance_valid(_barrier) and _barrier.waiting: _barrier.call("_wake")
	var error: String = ""
	for main: Node in _ec_native_handles:
		if not is_instance_valid(main): continue
		var level: CinderLevel = main.get("active_level") as CinderLevel
		var hero: CinderPlayer = main.get("player") as CinderPlayer
		var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler if level != null else null
		var source: Node3D = (level.get("sources") as Dictionary).get(EC_ID) as Node3D if level != null else null
		var current: String = await _ec_dispose_one({"main": main, "level": level, "hero": hero, "scheduler": scheduler, "source": source})
		if error.is_empty(): error = current
	_ec_native_handles.clear()
	var paths: Array[String] = []
	var scene_refs: Array[WeakRef] = []
	for scene: PackedScene in _ec_scene_handles:
		paths.append(scene.resource_path); scene_refs.append(weakref(scene))
	_ec_scene_handles.clear()
	_game = null; _level = null; _hero = null; _scheduler = null; _echo = null; _stalker = null; _barrier = null
	for _i: int in range(120):
		await process_frame
		var released: bool = true
		for ref: WeakRef in scene_refs:
			if ref.get_ref() != null: released = false
		if released: break
	for path: String in paths:
		if ResourceLoader.has_cached(path) and error.is_empty(): error = "TEST packed component scene remains cached after disposal"
	if (not get_nodes_in_group("enemies").is_empty() or not get_nodes_in_group("required_cues").is_empty()) and error.is_empty(): error = "Native component cleanup left enemy/cue group residue"
	_ec_running = false
	paused = false
	_ec_dispose_result = error
	_ec_disposing = false
	ec_component_disposed.emit()
	return error

## OPTIONAL append to focused test; pass Callable(self,"_ecp_portrait") to
## _ec_run("--east-component-portrait", ...). This is unexecuted draft only.
var _ecp_draw_seen: bool = false

func _ecp_view_error() -> String:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	if camera == null or hud == null or camera != _hero.get_viewport().get_camera_3d() or camera.get_world_3d() != _hero.get_world_3d(): return "Actual component native Camera/HUD/world required"
	var union: Dictionary = _level.call("camera_framing_union", "", [], true, false)
	if not String(union.get("error", "Missing native current union")).is_empty(): return String(union.get("error"))
	var points: Array = union.points.duplicate()
	points.append_array(_game.call("player_camera_framing_points_for", _hero, camera))
	# Also require the actual nearby east stone to read in this TEST image.
	var stone: Dictionary = (_level.get("_stones") as Dictionary).get("useful-east-stone", {})
	if stone.is_empty(): return "Actual retained native east shore stone unavailable"
	_level.call("_append_mesh", points, stone.mesh, stone.view.global_transform)
	return String(_game.call("camera_framing_error_for_context", points, _hero, camera, hud))

func _ecp_labels(node: Node, rows: Array) -> void:
	if node is Label:
		var label: Label = node as Label
		rows.append([String(_game.get_path_to(label)), label.text, label.is_visible_in_tree(), label.global_position, label.size, label.get_theme_font_size("font_size")])
	for child: Node in node.get_children(): _ecp_labels(child, rows)

func _ecp_optics() -> Dictionary:
	var hud: GameHUD = _game.get("hud") as GameHUD
	var labels: Array = []; _ecp_labels(hud, labels)
	return {"camera": _ec_camera(_game), "hud": [hud.visible, hud.combat_safe_rect(), labels]}

func _ecp_render(node: Node, rows: Array) -> void:
	if node is Node3D:
		var physical: Node3D = node as Node3D
		var row: Array = [String(_level.get_path_to(node)), str(node.get_instance_id()), physical.transform, physical.global_transform, physical.visible, physical.is_visible_in_tree()]
		if node is CollisionObject3D:
			var body: CollisionObject3D = node as CollisionObject3D
			row.append_array([body.collision_layer, body.collision_mask, node.is_in_group("enemies")])
		if node is CollisionShape3D:
			var collision: CollisionShape3D = node as CollisionShape3D
			row.append_array([collision.disabled, str(collision.shape.get_instance_id()) if collision.shape != null else ""])
		if node is MeshInstance3D:
			var mesh: MeshInstance3D = node as MeshInstance3D
			row.append_array([str(mesh.mesh.get_instance_id()) if mesh.mesh != null else "", str(mesh.material_override.get_instance_id()) if mesh.material_override != null else "", mesh.layers])
		if node is Sprite3D:
			var sprite: Sprite3D = node as Sprite3D
			row.append_array([str(sprite.texture.get_instance_id()) if sprite.texture != null else "", sprite.pixel_size, sprite.offset, sprite.modulate, sprite.layers])
		rows.append(row)
	for child: Node in node.get_children(): _ecp_render(child, rows)

func _ecp_sha(bytes: PackedByteArray) -> String:
	if bytes.is_empty(): return ""
	var digest := HashingContext.new()
	if digest.start(HashingContext.HASH_SHA256) != OK or digest.update(bytes) != OK: return ""
	return digest.finish().hex_encode()

func _ecp_portrait(main: Node, level: CinderLevel, hero: CinderPlayer, scheduler: CinderThreatScheduler, warning: Dictionary) -> Dictionary:
	if DisplayServer.get_name() == "headless" or not paused or main != _game or level != _level or hero != _hero or scheduler != _scheduler: return {"error": "Actual graphical paused component/native context required"}
	var hud: GameHUD = main.get("hud") as GameHUD
	var bench: CanvasLayer = main.get("bench") as CanvasLayer
	for _i: int in range(2): await process_frame
	var native: Dictionary = level.call("ece_native_pair")
	var playback: Dictionary = _echo.call("state")
	var lease: Dictionary = scheduler.replay_reservation_state(String(playback.get("reservation_id", "")))
	var error: String = _ecp_view_error()
	if hud == null or not hud.visible or bench == null or native.is_empty() or warning.is_empty() or error != "" or _echo.call("source_phase") != "warning" or lease.is_empty() or lease.get("source_instance_id") != _echo.get_instance_id(): return {"error": "Actual paused east warning/native view unavailable: " + error}
	var input_state: Dictionary = main.call("get_input_observation_state")
	var optics: Dictionary = _ecp_optics()
	var render: Array = []; _ecp_render(level, render)
	if input_state.is_empty() or optics.is_empty() or render.is_empty(): return {"error": "Nonempty native/input/optics/render witnesses required"}
	var before: Dictionary = {"native": var_to_bytes(native), "input": var_to_bytes(input_state), "optics": var_to_bytes(optics), "render": var_to_bytes(render)}
	for key: String in before:
		if (before[key] as PackedByteArray).is_empty(): return {"error": "Empty typed witness: " + key}
	var bench_visible: bool = bench.visible
	hud.hide_overlay(); bench.visible = false # Disclosed menu-only exclusion.
	_ecp_draw_seen = false
	RenderingServer.frame_post_draw.connect(_ecp_on_draw)
	for _i: int in range(120):
		await process_frame
		if _ecp_draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(_ecp_on_draw): RenderingServer.frame_post_draw.disconnect(_ecp_on_draw)
	var picture: Image = root.get_texture().get_image() if _ecp_draw_seen else null
	hud.show_pause(); bench.visible = bench_visible
	var render_after: Array = []; _ecp_render(level, render_after)
	var native_after: Dictionary = level.call("ece_native_pair")
	var unchanged: bool = not native_after.is_empty() and before.native == var_to_bytes(native_after) and before.input == var_to_bytes(main.call("get_input_observation_state")) and before.optics == var_to_bytes(_ecp_optics()) and before.render == var_to_bytes(render_after)
	error = _ecp_view_error()
	if not _ecp_draw_seen or picture == null or picture.get_size().x not in [339, 340] or picture.get_size().y != 736 or not paused or not unchanged or not error.is_empty() or bench.visible != bench_visible or not hud.visible: return {"error": "Actual paused east draw/custody failed", "draw_observed": _ecp_draw_seen, "unchanged": unchanged, "native_view_error": error}
	var folder: String = "res://captures/act3/mirror-sea-arrangement/east-component-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path: String = folder.path_join("01-declared-challenge-east-warning.png")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) != OK or picture.save_png(path) != OK: return {"error": "Actual native PNG could not be written"}
	var pins: Dictionary = {}
	for key: String in before:
		var bytes: PackedByteArray = before[key]
		var witness_path: String = folder.path_join(key + ".var.bin")
		var stream: FileAccess = FileAccess.open(witness_path, FileAccess.WRITE)
		if stream == null: return {"error": "Native witness output unavailable: " + key}
		stream.store_buffer(bytes); stream.flush(); stream.close()
		pins[key] = {"path": key + ".var.bin", "bytes": bytes.size(), "sha256": _ecp_sha(bytes)}
		if FileAccess.get_sha256(witness_path) != pins[key].sha256: return {"error": "Typed witness byte pin differs: " + key}
	var receipt: Dictionary = {"schema_version": 1, "test_only": true, "kind": "a3-l3-declared-east-component-warning-1", "runtime_sha256": FileAccess.get_sha256(RUNTIME_PATH), "component_sha256": FileAccess.get_sha256(EC_Component.resource_path), "png_sha256": FileAccess.get_sha256(path), "actual_dimensions": [picture.get_size().x, picture.get_size().y], "clock_s": scheduler.get_clock(), "source_id": EC_ID, "phase": "warning", "generation": native.source.generation, "reservation_id": playback.reservation_id, "recipe_id": EC_Runtime.CHALLENGE_RECIPE, "native_state_input_optics_render_unchanged": unchanged, "typed_witnesses": pins, "parent_route_or_save_credit": false, "scope": "One actual paused declared Challenge east warning view; HUD overlay/bench excluded and restored, no source hidden. No earned L3 arrival, canonical parent save, full route, active view or human balance credit."}
	var stream: FileAccess = FileAccess.open(path + ".json", FileAccess.WRITE)
	var wire: String = ExactJson.stringify(receipt)
	if stream == null or wire.is_empty(): return {"error": "Actual exact image receipt unavailable"}
	stream.store_string(wire + "\n"); stream.flush(); stream.close()
	return {"error": "", "path": ProjectSettings.globalize_path(path), "png_sha256": receipt.png_sha256, "component_only": true}

func _ecp_on_draw() -> void: _ecp_draw_seen = true

## PRIVATE appendable composition adapter. Keep frozen component8170/east5fc6/
## portrait93c unchanged. No parser/native/draw result is implied by this source.
var _eca_selector: String = ""
var _eca_result_folder: String = ""
var _eca_actual_result: Dictionary = {}
var _eca_summary: Dictionary = {}
var _eca_portrait_context: Dictionary = {}
var _eca_portrait_passed: bool = false

func _eca_run(selector: String) -> void:
	_eca_selector = selector
	_p3_complete = false
	var result: Dictionary
	if not _p3t_verify_original():
		result = {"error": "Sealed genuine OLD manifest/file guard failed; component not executed"}
	else:
		var writer: Callable = Callable(self, "_eca_portrait") if selector == "--east-component-portrait" else Callable()
		result = await _ec_run(selector, writer)
	# The watchdog owns final disposal/exit once it sets this flag. Never revive it.
	if _p3_done: return
	_eca_actual_result = result.duplicate(true)
	var actual_error: String = String(result.get("error", "Missing actual component error field"))
	var refinement: bool = result.get("needs_integration_refinement", false) == true or result.get("outcome", "") == "no_useful_difference"
	var portrait_ok: bool = selector != "--east-component-portrait" or _eca_portrait_passed
	_expect(not result.is_empty() and actual_error.is_empty(), "actual declared component returns its literal native outcome", actual_error)
	if selector == "--east-component-portrait":
		_expect(portrait_ok, "actual paused portrait completes its full draw/custody and PNG write", actual_error)
	var archive_error: String = _eca_archive(result, refinement, portrait_ok)
	_expect(archive_error.is_empty(), "full actual component result and small summary persist exactly", archive_error)
	_p3_complete = not result.is_empty() and actual_error.is_empty() and not refinement and portrait_ok and archive_error.is_empty()
	if refinement:
		print("Mirror Sea east component outcome remains literal: ", result.get("outcome", ""), "; needs_integration_refinement=true; complete=false")
	await _p3_finish()

func _eca_portrait(main: Node, level: CinderLevel, hero: CinderPlayer, scheduler: CinderThreatScheduler, warning: Dictionary) -> Dictionary:
	# These are actual callback observations, not defaults for missing case data.
	_eca_portrait_context = {"label": "changed-challenge-portrait", "kit": hero.equipment.snapshot().duplicate(true), "hero_hp": hero.hp, "source_hp": _echo.get("hp"), "native_ticks": _ec_ticks}
	var result: Dictionary = await _ecp_portrait(main, level, hero, scheduler, warning)
	var path: Variant = result.get("path")
	_eca_portrait_passed = not result.is_empty() and result.get("error") == "" and _ecp_draw_seen and path is String and not path.is_empty() and FileAccess.file_exists(path) and FileAccess.get_sha256(path) == result.get("png_sha256")
	# The frozen portrait result is returned without relabeling its error or fields.
	return result

func _eca_vec3(value: Variant) -> Variant:
	if value is Vector3: return [value.x, value.y, value.z]
	return null # Missing/unexecuted observation stays missing, never a zero vector.

func _eca_case_summary(row: Dictionary, index: int) -> Dictionary:
	var requested: Array[String] = ["canonical-challenge-baseline", "changed-challenge-baseline", "changed-challenge-combined-short-slow"]
	if _eca_selector == "--east-component-portrait": requested = ["changed-challenge-portrait"]
	var selected_label: String = requested[index] if index < requested.size() else ""
	var observed: Dictionary = row
	if _eca_selector == "--east-component-portrait" and index == 0 and not _eca_portrait_context.is_empty(): observed = _eca_portrait_context
	var landings: Array = []
	var recorded_landings: Variant = row.get("executed_landings")
	if recorded_landings is Array:
		for landing: Variant in recorded_landings: landings.append(_eca_vec3(landing))
	var portrait: Dictionary = row.get("portrait", {}) if row.get("portrait", {}) is Dictionary else {}
	return {"requested_label": selected_label, "actual_label": row.get("label", observed.get("label", "")), "kit": observed.get("kit"), "hero_hp": observed.get("hero_hp"), "source_hp": observed.get("source_hp"), "native_ticks": observed.get("native_ticks"), "primary_origin": _eca_vec3(row.get("primary_origin")), "executed_landings": landings, "landings_recorded": recorded_landings is Array, "error": row.get("error", "Missing actual case error field"), "reason": row.get("reason", ""), "native_refusals": row.get("native_refusals", []), "png_path": portrait.get("path", ""), "png_sha256": portrait.get("png_sha256", "")}

func _eca_write(path: String, bytes: PackedByteArray) -> String:
	if bytes.is_empty() or FileAccess.file_exists(path): return "New nonempty result output required: " + path
	var stream: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if stream == null: return "Result output unavailable: " + path
	stream.store_buffer(bytes); stream.flush()
	var status: Error = stream.get_error()
	stream.close()
	if status != OK or FileAccess.get_file_as_bytes(path) != bytes: return "Result bytes did not persist exactly: " + path
	return ""

func _eca_archive(result: Dictionary, refinement: bool, portrait_ok: bool) -> String:
	if result.is_empty(): return "No nonempty actual component result to archive"
	var bytes: PackedByteArray = var_to_bytes(result)
	var text: String = var_to_str(result)
	if bytes.is_empty() or text.is_empty(): return "Full native Variant result encoding is empty"
	_eca_result_folder = "res://captures/act3/mirror-sea-arrangement/result-%s-%d-%d" % ["portrait" if _eca_selector == "--east-component-portrait" else "component", OS.get_process_id(), Time.get_ticks_usec()]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_eca_result_folder)): return "Unique result folder already exists"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_eca_result_folder)) != OK: return "Unique result folder could not be created"
	var native_path: String = _eca_result_folder.path_join("result.var.bin")
	var text_path: String = _eca_result_folder.path_join("result.var.txt")
	var error: String = _eca_write(native_path, bytes)
	if not error.is_empty(): return error
	error = _eca_write(text_path, (text + "\n").to_utf8_buffer())
	if not error.is_empty(): return error
	var cases: Array = []
	var actual_cases: Variant = result.get("cases", [])
	if actual_cases is Array:
		for index: int in range(actual_cases.size()):
			if not actual_cases[index] is Dictionary: return "Actual result contains a non-dictionary case; full result retained"
			cases.append(_eca_case_summary(actual_cases[index], index))
	_eca_summary = {"schema_version": 1, "kind": "a3-l3-declared-east-component-result-1", "test_only": true, "selector": _eca_selector, "legacy_manifest_sha256": P3T_LEGACY_MANIFEST_SHA256, "error": result.get("error", "Missing actual component error field"), "outcome": result.get("outcome", ""), "needs_integration_refinement": refinement, "portrait_full_draw_passed": _eca_portrait_passed if _eca_selector == "--east-component-portrait" else null, "completion_eligible_before_final_cleanup": result.get("error") == "" and not refinement and portrait_ok, "cases": cases, "full_result": {"native_file": "result.var.bin", "native_bytes": bytes.size(), "native_sha256": FileAccess.get_sha256(native_path), "text_file": "result.var.txt", "text_sha256": FileAccess.get_sha256(text_path)}, "parent_route_or_save_credit": false, "human_balance_credit": false, "scope": "Actual declared isolated east component only. Missing case fields remain null/empty; requested labels do not fabricate observations. Full native Variant/text retain failures and refusal details. This summary is not a closed-run receipt or level acceptance."}
	var wire: String = ExactJson.stringify(_eca_summary)
	if wire.is_empty(): return "Small result summary is not ExactJSON safe; full native/text result retained"
	error = _eca_write(_eca_result_folder.path_join("summary.json"), (wire + "\n").to_utf8_buffer())
	if not error.is_empty(): return error
	print("Mirror Sea east component actual result: ", ProjectSettings.globalize_path(_eca_result_folder), "; error=", _eca_summary.error, "; outcome=", _eca_summary.outcome, "; needs_integration_refinement=", refinement)
	return ""
