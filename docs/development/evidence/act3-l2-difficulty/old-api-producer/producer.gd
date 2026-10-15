extends SceneTree
## NEW execution of sealed original API1; never historical payload recovery.
## Actual canonical scene/native writer; TEST caller profile and stable Hero
## relocation only. No HP/phase/lease/clock/death or saved-packet assignments.

const MainScene = preload("res://scenes/main.tscn")
const ProfileMain = preload("res://.cinder/a3-l2-legacy-fixture-prepare-20261015/profile_main.gd")
const Parent = preload("res://scripts/acts/act3/living_forest_level.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const LEVEL_PATH: String = "res://scenes/acts/act3/a3_l2_living_forest.tscn"
const ROOT_ID: String = "l2-promise-root"

class EndTick extends Node:
	signal settled
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 300
	func _physics_process(_delta: float) -> void:
		settled.emit.call_deferred()

var game: Node
var hero: CinderPlayer
var level: CinderLevel
var scheduler: CinderThreatScheduler
var barrier: EndTick
var profile: String = ""
var out: String = ""
var test_root: String = ""
var rows: Array[Dictionary] = []
var packets: Array[Dictionary] = []
var checkpoints: Array[Dictionary] = []
var first_failure: Dictionary = {}
var failures: int = 0
var complete: bool = false
var finishing: bool = false
var source_before: Dictionary = {}
var source_names: Array[String] = []
var old_fps: int
var old_audio: AudioBusLayout

func _initialize() -> void:
	out = OS.get_environment("CINDER_A3_L2_LEGACY_OUTPUT")
	test_root = "user://test-a3-l2-new-api1-producer-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	var supplied: Variant = JSON.parse_string(OS.get_environment("CINDER_A3_L2_LEGACY_SOURCES"))
	if supplied is Array:
		for item: Variant in supplied:
			if item is String: source_names.append(item)
	source_before = _sources()
	_run.call_deferred()

func _run() -> void:
	create_timer(150.0, true).timeout.connect(func() -> void:
		if not finishing: _expect(false, "bounded 150-second native caller watchdog"); _finish.call_deferred())
	root.size = Vector2i(540, 1170)
	if not _expect(not out.is_empty() and not source_names.is_empty() and OS.get_cmdline_user_args().is_empty(), "unique output and fixed source observations; no CLI scenario mutation"):
		await _finish(); return
	for selected: String in ["standard", "challenge"]:
		profile = selected
		if not await _open(): await _finish(); return
		game.call("resume_lab")
		if not await _wait(func() -> bool: return hero.get_threat_response_state().stable and hero.global_position.z > 38.0, "real settled entrance floor/Player", 6.0): await _finish(); return
		game.call("open_bench")
		if not await _capture("entrance"): await _finish(); return
		# Disclosed TEST position on the same actual continuous floor. Native
		# ticks create both ordered entries and checkpoint signals themselves.
		if not _expect(paused and hero.get_threat_response_state().stable, "stable native Hero before representative TEST relocation"): await _finish(); return
		hero.global_position = Vector3(0, hero.global_position.y, 24.0)
		game.call("resume_lab")
		if not await _wait(func() -> bool: return _root_warning(), "actual original Root promise warning and live native lease", 20.0): await _finish(); return
		game.call("open_bench")
		if not await _capture("root-warning"): await _finish(); return
		if not await _dispose(): await _finish(); return
	complete = true
	await _finish()

func _open() -> bool:
	paused = false
	game = MainScene.instantiate()
	game.set_script(ProfileMain)
	game.set("legacy_test_profile", profile)
	game.set("level_scene_path", LEVEL_PATH)
	if not _expect(not game.is_inside_tree() and game.scene_file_path == "res://scenes/main.tscn", "actual Main PackedScene identity retained before TEST subclass enters tree"): return false
	root.add_child(game)
	game.call("open_bench")
	hero = game.get("player") as CinderPlayer
	level = game.get("active_level") as CinderLevel
	scheduler = level.get("threat_scheduler") as CinderThreatScheduler if level != null else null
	barrier = EndTick.new(); game.add_child(barrier)
	if level != null:
		level.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void:
			checkpoints.append({"profile": profile, "level_id": id, "checkpoint_id": checkpoint, "boundary_kind": kind}))
	await process_frame; await process_frame
	return _expect(paused and hero != null and level != null and scheduler != null and game.call("get_difficulty_preference") == profile and level.level_id == "A3-L2" and level.scene_file_path == LEVEL_PATH and level.get_script() == Parent and level.contract_error().is_empty() and scheduler.encounter_profile().id == profile, "canonical scene/original API1 parent/native Scheduler consume explicit TEST profile", level.contract_error() if level != null else "missing level")

func _wait(predicate: Callable, label: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	for _frame: int in range(2400):
		await barrier.settled
		if finishing: return false
		if not _expect(is_instance_valid(hero) and not hero.dead and level.contract_error().is_empty(), "live native boundary during " + label): return false
		if predicate.call() == true: return _expect(true, label)
		if paused or Time.get_ticks_msec() > deadline: break
	return _expect(false, "bounded native wait: " + label)

func _root_warning() -> bool:
	var source: Node = (level.get("sources") as Dictionary).get(ROOT_ID)
	if source == null: return false
	var state: Dictionary = source.call("state")
	var mechanism: CinderLaneMechanism = source.call("get_mechanism")
	if state.get("phase") != "warning" or state.get("dead") != false or state.mechanism.get("status") != "running": return false
	var control: Dictionary = scheduler.source_control_state(mechanism)
	for record: Dictionary in control.get("reservations", []):
		if record.id == state.mechanism.reservation_id and record.source_instance_id == mechanism.get_instance_id() and record.profile_id == profile: return true
	return false

func _capture(stage: String) -> bool:
	await process_frame
	var player_packet: Dictionary = hero.snapshot_state()
	var level_packet: Dictionary = level.snapshot_state()
	if not _expect(paused and not player_packet.is_empty() and not level_packet.is_empty() and level_packet.local.api_revision == "act3-living-forest-level-1" and level_packet.local.schema_version is int and level_packet.local.schema_version == 1 and level_packet.local_snapshot_version == 1 and level_packet.local.scheduler.profile.id == profile and not level_packet.local.has("arrangement"), "actual original typed API1/schema1 Player+complete Level writers close: " + stage, hero.last_snapshot_error + "; " + level.last_snapshot_error): return false
	var pair: Dictionary = {"player": player_packet, "level": level_packet}
	var wire: String = Exact.stringify(pair)
	var decoded: Dictionary = Exact.parse(wire)
	if not _expect(not wire.is_empty() and decoded.get("accepted") == true and Exact.stringify(decoded.value) == wire and hero.snapshot_error(player_packet).is_empty() and level.snapshot_error_with_player(level_packet, player_packet).is_empty(), "native original writer/reader retain exact scalar types/bits without packet rewriting: " + stage): return false
	if stage == "entrance":
		if not _expect(level_packet.local.route.entries.is_empty() and level_packet.local.route.deaths.is_empty() and level_packet.local.scheduler.reservations.is_empty(), "actual settled entrance has no fabricated entry/death/lease history"): return false
	else:
		if not _expect(_root_warning() and level_packet.local.route.entries.size() == 2 and level_packet.progress.checkpoint_id == "root-promise-entry" and not level_packet.local.scheduler.reservations.is_empty(), "actual Root warning retains real ordered entry/checkpoint and native lease"): return false
	var name: String = profile + "-" + stage
	var file := FileAccess.open(out.path_join(name + ".exact.json"), FileAccess.WRITE)
	if not _expect(file != null, "opaque native Exact unit output opens"): return false
	file.store_string(wire); file.close()
	var store_path: String = test_root + name + ".json"
	var store: CinderSaveStore = Store.new(store_path)
	if not _expect(store.write_payload(pair), "actual format2 Store writes the original native caller pair", store.last_error): return false
	var saved_bytes: PackedByteArray = FileAccess.get_file_as_bytes(store_path)
	var envelope: Variant = JSON.parse_string(saved_bytes.get_string_from_utf8())
	var from_disk: Dictionary = Store.new(store_path).read_payload()
	if not _expect(envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") == wire and Exact.stringify(from_disk) == wire and Exact.stringify({"player": hero.snapshot_state(), "level": level.snapshot_state()}) == wire, "independent actual Store read and original frozen native pair retain the same exact wire"): return false
	file = FileAccess.open(out.path_join(name + ".store.json"), FileAccess.WRITE)
	if not _expect(file != null, "raw original format2 Store byte copy opens"): return false
	file.store_buffer(saved_bytes); file.close()
	packets.append({"profile": profile, "stage": stage, "exact_file": name + ".exact.json", "exact_sha256": wire.sha256_text(), "exact_bytes": wire.to_utf8_buffer().size(), "store_file": name + ".store.json", "store_sha256": FileAccess.get_sha256(out.path_join(name + ".store.json")), "store_bytes": saved_bytes.size(), "main_scene": game.scene_file_path, "level_scene": level.scene_file_path, "level_script": level.get_script().resource_path, "parent_api": level_packet.local.api_revision, "parent_schema": level_packet.local.schema_version, "original_store_uri": store_path, "actual_scheduler_profile": level_packet.local.scheduler.profile.id, "scope": "New execution of original API1. Whole native Player+Level pair; TEST caller preference and representative stable Hero relocation. Real native entries/checkpoint/lease, no state/packet forgery; not a CampaignAttempts session or historical payload reuse."})
	return true

func _dispose() -> bool:
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		_collect(game, refs)
		if is_instance_valid(level): level.exit_level()
		if is_instance_valid(game.get("fx")): game.get("fx").clear()
		game.free()
	game = null; hero = null; level = null; scheduler = null; barrier = null
	await process_frame
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return _expect(false, "normal owned Main/native descendants freed")
	return _expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal owned Main/native source/cue cleanup")

func _collect(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _collect(child, refs)

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	var row: Dictionary = {"check": rows.size() + 1, "ok": ok, "label": label, "detail": detail}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
		print("FAIL legacy producer: " + label + "; " + detail)
	return ok

func _sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in source_names:
		result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else null
	return result

func _finish() -> void:
	if finishing: return
	finishing = true
	paused = true
	if is_instance_valid(game): await _dispose()
	var dir := DirAccess.open(test_root)
	if dir != null:
		for name: String in dir.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	paused = false
	var report: Dictionary = {"schema_version": 1, "kind": "new-executed-original-a3-l2-api1-producer", "checks": rows.size(), "failures": failures, "rows": rows, "first_failure": first_failure, "complete": complete, "success": complete and failures == 0, "source_before": source_before, "source_after": _sources(), "packets": packets, "actual_checkpoint_signals": checkpoints, "scope": "New caller fixture executes untouched canonical API1 parent/data and native actors under explicit Standard/Challenge preferences. Exact opaque Player+Level units and raw actual Store bytes; representative TEST position, no HP/clock/phase/lease/packet rewriting. No CampaignAttempts/production Shell, historical payload recovery, full route, visual, balance or performance credit."}
	var path: String = out.path_join("native-report.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: print("Legacy producer report write failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("CINDER_A3_L2_LEGACY_REPORT path=" + path + " sha256=" + FileAccess.get_sha256(path))
	print("A3-L2 original API1 producer: %d checks/%d failures; complete=%s; packets=%d" % [rows.size(), failures, str(complete), packets.size()])
	quit(0 if complete and failures == 0 else 1)
