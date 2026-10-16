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
	var prior_clock: float = _scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0
	var actor_clock: float = _hero.get_world_action_clock() if is_instance_valid(_hero) else -1.0
	var actions: Array[Dictionary] = _hero.get_world_action_records() if is_instance_valid(_hero) else []
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
	await _dispose_host(false) # Historical helper's native WeakRefs/group checks.
	await _p3_dispose_preview()
	if node_added.is_connected(_watch_new_node): node_added.disconnect(_watch_new_node)
	_expect(_canonical_registry_bytes.is_empty() or FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH) == _canonical_registry_bytes,"canonical Registry bytes remain exact")
	_cleanup_owned_path(_test_root)
	print("Mirror Sea arrangement ORIGINAL producer: %d checks/%d failures; complete=%s; driver_observations=%d; last_scheduler_clock_s=%.9f; MAIN Challenge entrance Scheduler1/first Echo Scheduler3/latest CP2 only; no east/full-route/new-reader/portrait credit." % [_checks,_failures,str(_p3_complete),_p3_driver_observations,_p3_last_clock])
	quit(0 if _failures == 0 and _p3_complete else 1)
