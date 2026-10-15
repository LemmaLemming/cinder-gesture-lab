extends SceneTree
## Literal executed-original API1 Player+Level units, never campaign sessions.
## TEST Main overrides only current preference. Its ordinary preview is disposed;
## a fresh canonical L2 candidate uses the real public paused-construction API.
## No actor state, native geometry, clock, HP or saved unit is rewritten to pass.

const MainScene = preload("res://scenes/main.tscn")
const LevelScene = preload("res://scenes/acts/act3/a3_l2_living_forest.tscn")
const Parent = preload("res://scripts/acts/act3/living_forest_level.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const LEVEL_PATH: String = "res://scenes/acts/act3/a3_l2_living_forest.tscn"
const FIXTURES: String = "res://tests/acts/act3/fixtures/a3_l2_difficulty_legacy/"
const PRODUCER_REPORT_SHA: String = "6fc995e76d490590eb52aed6bc9c5284e7c19f3839ac08949e115fb62860a794"
const ROOT_ID: String = "l2-promise-root"
const LITERAL_HASHES: Dictionary = {
	"standard-entrance": ["bd9e79e37eca8dc91125879f2d8d8d48c573147f3ae1efe31e75dd209c56dba3", "fc2d3bb8901ca3239b251236ca74b5b082f63b4dd1612d1c3b0d07579ac954f5"],
	"standard-root-warning": ["14e0ceb50dca675a598fae7faacbb3e668c47f73c86d8e2fae12f6342605a067", "8166ec1431c29315461b6be493e0eda4ec26483539a8523c50af7b415420b2c1"],
	"challenge-entrance": ["75a86352664f0ee9df24089cf98f80ba97ace34fe7ba264e2c71f1cbd0d67280", "5b759033244de64bcb414b045e95cc4530d0a174c6b0bae271861be3cd690c9e"],
	"challenge-root-warning": ["f87fdfc914da91ee80c8b062b0a2d03d84db1d7ca55ecc17b027575bc1ffc238", "9bcd934ed164fd7c0cad53af54d5f63d79c1195f3131ca6141c5a76881ea4425"],
}

class PreferenceMain:
	extends "res://scripts/game.gd"
	var legacy_current_preference: String = "standard"
	func get_difficulty_preference() -> String:
		return legacy_current_preference

var game: Node
var hero: CinderPlayer
var level: CinderLevel
var scheduler: CinderThreatScheduler
var checks: int = 0
var failures: int = 0
var rows: Array[Dictionary] = []
var first_failure: Dictionary = {}
var receipts: Array[Dictionary] = []
var quiet_events: Array[String] = []
var source_before: Dictionary = {}
var test_root: String
var report_path: String
var old_fps: int
var old_audio: AudioBusLayout
var complete: bool = false
var finishing: bool = false

func _initialize() -> void:
	test_root = "user://test-a3-l2-arrangement-legacy-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = test_root + "report.json"
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
		else:
			_expect(false, "only an explicit report destination is accepted", argument)
	source_before = _sources()
	_run.call_deferred()

func _run() -> void:
	create_timer(90.0, true).timeout.connect(func() -> void:
		if not finishing: _expect(false, "bounded 90-second legacy test watchdog"); _finish.call_deferred())
	root.size = Vector2i(540, 1170)
	var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURES + "PROVENANCE.json"))
	if not _expect(failures == 0 and provenance is Dictionary and provenance.get("records") is Array and provenance.records.size() == 4 and provenance.get("producer_report") is Dictionary and provenance.producer_report.get("sha256") == PRODUCER_REPORT_SHA, "four literal executed-original API1 units retain native producer provenance"):
		await _finish(); return
	for record: Dictionary in provenance.records:
		if not await _exercise(record): await _finish(); return
	complete = true
	await _finish()

func _exercise(record: Dictionary) -> bool:
	var name: String = String(record.profile) + "-" + String(record.stage)
	var wire_path: String = FIXTURES + name + ".exact.json"
	var raw_path: String = FIXTURES + name + ".store.json"
	if not _expect(LITERAL_HASHES.has(name) and FileAccess.get_sha256(wire_path) == LITERAL_HASHES[name][0] and FileAccess.get_sha256(raw_path) == LITERAL_HASHES[name][1] and record.exact_sha256 == LITERAL_HASHES[name][0] and record.store_sha256 == LITERAL_HASHES[name][1], "original exact/raw Store byte hashes: " + name): return false
	var wire: String = FileAccess.get_file_as_string(wire_path)
	var parsed: Dictionary = Exact.parse(wire)
	if not _expect(parsed.get("accepted") == true and parsed.get("value") is Dictionary, "literal native wire decodes without reencoding: " + name): return false
	var unit: Dictionary = parsed.value
	if not _expect(_legacy_shape(unit, String(record.profile)) and Exact.stringify(unit) == wire, "whole original API1/schema1 pair retains exact scalar types/bits: " + name): return false
	var opposite: String = "challenge" if record.profile == "standard" else "standard"
	if not await _open(unit, opposite): return false
	if not _expect(hero.snapshot_error(unit.player).is_empty() and _pair_error(unit).is_empty(), "fresh candidate independently prevalidates entire saved Hero and Level: " + name, hero.last_snapshot_error + "; " + _pair_error(unit)): return false
	var identities: Dictionary = _identities()
	if not _expect(hero.restore_state(unit.player), "actual shared Hero restores first: " + name, hero.last_snapshot_error): return false
	if not _expect(level.restore_state(unit.level), "actual Level quietly restores after Hero: " + name, level.last_snapshot_error): return false
	if not _expect(paused and level.is_restore_candidate() and level.hero == hero and level.effects == game.get("fx") and level.shared_shell == game and _identities() == identities and quiet_events.is_empty() and _wire() == wire, "exact full legacy recapture and native recipient identities remain quiet: " + name, level.last_snapshot_error): return false
	if not _expect(game.call("get_difficulty_preference") == opposite and scheduler.encounter_profile().id == record.profile and _legacy_shape({"player": hero.snapshot_state(), "level": level.snapshot_state()}, String(record.profile)), "opposite current preference cannot inject API2 receipt or remap saved original arrangement/profile: " + name): return false
	if record.stage == "entrance":
		if not _expect(unit.level.local.route.entries.is_empty() and unit.level.local.route.deaths.is_empty() and unit.level.local.scheduler.reservations.is_empty(), "genuine old entrance remains free of fabricated progression or leases"): return false
	else:
		var actor: Node = (level.get("sources") as Dictionary)[ROOT_ID]
		var state: Dictionary = actor.call("state")
		if not _expect(unit.level.local.route.entries.size() == 2 and unit.level.progress.checkpoint_id == "root-promise-entry" and state.phase == "warning" and state.mechanism.status == "running" and unit.level.local.scheduler.reservations.size() == 1, "genuine old Root warning/lease and actual checkpoint remain exact"): return false
	var disk_path: String = test_root + name + ".json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))
	var file := FileAccess.open(disk_path, FileAccess.WRITE)
	if not _expect(file != null, "unique TEST raw Store destination opens"): return false
	file.store_buffer(FileAccess.get_file_as_bytes(raw_path)); file.close()
	var store: CinderSaveStore = Store.new(disk_path)
	store.payload_validator = _pair_error
	var reread: Dictionary = store.read_payload()
	if not _expect(not store.loaded_backup and store.generation == 1 and Exact.stringify(reread) == wire and FileAccess.get_sha256(disk_path) == LITERAL_HASHES[name][1], "independent actual format2 Store reread retains original raw bytes and complete native pair: " + name, store.last_error): return false
	for kind: String in ["recipe", "source-type", "placement", "entry", "death", "geometry"]:
		if not _refuse(_forge(unit, kind), kind, wire, store, identities): return false
	if not unit.level.local.scheduler.reservations.is_empty():
		if not _refuse(_forge(unit, "lease-geometry"), "lease-geometry", wire, store, identities): return false
	var independent: CinderSaveStore = Store.new(disk_path)
	independent.payload_validator = _pair_error
	if not _expect(Exact.stringify(independent.read_payload()) == wire and not independent.loaded_backup and _wire() == wire and quiet_events.is_empty(), "post-refusal fresh Store reader and whole native pair remain unchanged: " + name, independent.last_error): return false
	receipts.append({"name": name, "original_wire_sha256": wire.sha256_text(), "original_store_sha256": LITERAL_HASHES[name][1], "producer_report_sha256": PRODUCER_REPORT_SHA, "saved_profile": record.profile, "current_TEST_preference": opposite, "exact_recapture_sha256": _wire().sha256_text(), "actual_native_identities": identities, "scope": "Fresh paused actual Main/native Level candidate and actual format2 raw Store; no Shell/CampaignAttempts session or playable campaign Continue/Retry claim."})
	return await _dispose()

func _open(unit: Dictionary, opposite: String) -> bool:
	paused = false
	game = MainScene.instantiate()
	game.set_script(PreferenceMain)
	game.set("legacy_current_preference", opposite)
	game.set("level_scene_path", LEVEL_PATH)
	if not _expect(not game.is_inside_tree() and game.scene_file_path == "res://scenes/main.tscn", "actual Main identity retained before disclosed TEST preference subclass entry"): return false
	root.add_child(game)
	game.call("open_bench")
	hero = game.get("player") as CinderPlayer
	var preview: CinderLevel = game.get("active_level") as CinderLevel
	if not _expect(paused and hero != null and preview != null and game.get("level_load_error") == "", "actual Main provides shared Hero/effects/world and paused ordinary preview"): return false
	var preview_ref: WeakRef = weakref(preview)
	preview.exit_level(); preview.free()
	game.set("active_level", null)
	game.get("fx").clear()
	level = LevelScene.instantiate() as CinderLevel
	game.get("world").add_child(level)
	game.set("active_level", level)
	scheduler = level.get("threat_scheduler") as CinderThreatScheduler
	quiet_events.clear()
	level.completion_requested.connect(func(_id: String, _event: String) -> void: quiet_events.append("completion"))
	level.contact_exit_requested.connect(func(_id: String, _event: String) -> void: quiet_events.append("exit"))
	level.checkpoint_requested.connect(func(_id: String, _event: String, _kind: String) -> void: quiet_events.append("checkpoint"))
	hero.died.connect(func() -> void: quiet_events.append("Hero death"))
	hero.fired.connect(func(_kind: String) -> void: quiet_events.append("Hero fire"))
	hero.equipment_changed.connect(func(_id: String) -> void: quiet_events.append("Hero equipment"))
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: quiet_events.append("Hero action"))
	for actor: Node in (level.get("sources") as Dictionary).values():
		actor.connect("died", func(_where: Vector3) -> void: quiet_events.append("native source death"))
	await process_frame; await process_frame
	if finishing: return false
	if not _expect(paused and preview_ref.get_ref() == null and level.scene_file_path == LEVEL_PATH and level.get_script() == Parent and scheduler != null and level.contract_error().is_empty() and level.restore_candidate_construction_required(), "fresh actual API2 parent/native recipients registered while paused; original preview freed", level.contract_error()): return false
	return _expect(level.enter_restore_candidate(hero, game.get("fx"), game, unit.level, unit.player), "public fresh paused candidate constructs from saved API1 selection before pure validation", level.last_snapshot_error)

func _legacy_shape(unit: Dictionary, saved_profile: String) -> bool:
	if unit.size() != 2 or not unit.get("player") is Dictionary or not unit.get("level") is Dictionary or not unit.level.get("local") is Dictionary: return false
	var local: Dictionary = unit.level.local
	return unit.level.local_snapshot_version is int and unit.level.local_snapshot_version == 1 and local.size() == 6 and local.get("api_revision") == "act3-living-forest-level-1" and local.get("schema_version") is int and local.schema_version == 1 and not local.has("arrangement") and local.scheduler.profile.id == saved_profile and local.sources.size() == 9

func _pair_error(unit: Dictionary) -> String:
	if unit.size() != 2 or not unit.get("player") is Dictionary or not unit.get("level") is Dictionary: return "TEST caller requires the exact original Player+Level pair"
	if not is_instance_valid(hero) or not is_instance_valid(level): return "TEST caller requires actual native candidate recipients"
	var error: String = hero.snapshot_error(unit.player)
	return error if not error.is_empty() else level.snapshot_error_with_player(unit.level, unit.player)

func _forge(unit: Dictionary, kind: String) -> Dictionary:
	# Refusal-only copies. The original wire, restore input and donor never change.
	var forged: Dictionary = unit.duplicate(true)
	var local: Dictionary = forged.level.local
	match kind:
		"recipe": local["arrangement"] = {"recipe_id": "TEST-unearned-api2-recipe"}
		"source-type": local.sources[ROOT_ID].kind = "stalker"
		"placement": local.sources[ROOT_ID].actor.position[0] += 0.25
		"entry":
			if local.route.entries.is_empty(): local.route.entries.append({"id": "root-promise", "clock_s": 0.0, "hero_position": [0.0, 0.0, 24.0]})
			else: local.route.entries[0].id = "root-promise"
		"death": local.route.deaths[ROOT_ID] = {"clock_s": local.scheduler.clock_s, "source_position": local.sources[ROOT_ID].actor.position.duplicate()}
		"geometry": local.sources[ROOT_ID].actor.mechanism.configuration.geometry.outer_radius += 0.25
		"lease-geometry": local.scheduler.reservations[0].geometry.origin[0] += 0.25
	return forged

func _refuse(forged: Dictionary, kind: String, original_wire: String, store: CinderSaveStore, identities: Dictionary) -> bool:
	var disk_before: Dictionary = _disk_state(store.path)
	var generation: int = store.generation
	var error: String = _pair_error(forged)
	if not _expect(not error.is_empty() and _wire() == original_wire and _identities() == identities and quiet_events.is_empty(), "pure aggregate refusal preserves complete native donor: " + kind, error): return false
	if not _expect(not level.restore_state(forged.level), "actual public local restore atomically refuses forged " + kind, level.last_snapshot_error): return false
	if not _expect(not store.write_payload(forged), "actual Store semantic validator refuses forged " + kind, store.last_error): return false
	return _expect(_wire() == original_wire and _identities() == identities and quiet_events.is_empty() and _disk_state(store.path) == disk_before and store.generation == generation, "whole Player+Level/native identities/signals/raw primary/backup/files/generation remain exact after " + kind)

func _wire() -> String:
	return Exact.stringify({"player": hero.snapshot_state(), "level": level.snapshot_state()})

func _identities() -> Dictionary:
	var result: Dictionary = {"main": game.get_instance_id(), "hero": hero.get_instance_id(), "fx": game.get("fx").get_instance_id(), "level": level.get_instance_id(), "scheduler": scheduler.get_instance_id()}
	for id: String in level.get("sources"):
		var actor: Node = (level.get("sources") as Dictionary)[id]
		result[id] = actor.get_instance_id()
		if actor.has_method("get_mechanism"): result[id + "/attack"] = actor.call("get_mechanism").get_instance_id()
	return result

func _disk_state(path: String) -> Dictionary:
	var dir := DirAccess.open(test_root)
	var names: PackedStringArray = dir.get_files() if dir != null else PackedStringArray()
	names.sort()
	return {"primary": FileAccess.get_sha256(path), "backup": FileAccess.get_sha256(path + ".bak") if FileAccess.file_exists(path + ".bak") else null, "files": Array(names)}

func _dispose() -> bool:
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		_collect(game, refs)
		if is_instance_valid(level): level.exit_level()
		game.get("fx").clear()
		game.free()
	game = null; hero = null; level = null; scheduler = null
	await process_frame
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return _expect(false, "owned fresh Main/native descendant cleanup")
	return _expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal owned fresh Main/native source/cue cleanup")

func _collect(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _collect(child, refs)

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	checks += 1
	var row: Dictionary = {"check": checks, "ok": ok, "label": label, "detail": detail}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
		print("FAIL A3-L2 arrangement legacy: " + label + "; " + detail)
	return ok

func _sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [get_script().resource_path, FIXTURES + "PROVENANCE.json", "res://scripts/game.gd", "res://scripts/player.gd", "res://scripts/campaign/level.gd", "res://scripts/campaign/save_store.gd", "res://scripts/campaign/exact_json.gd", "res://scripts/acts/act3/living_forest_level.gd", "res://scripts/acts/act3/root_latcher.gd", "res://scripts/acts/act3/sunbound_stalker.gd", "res://data/campaign/act3/a3_l2_encounters.json", LEVEL_PATH, "res://scenes/main.tscn"]:
		result[path] = FileAccess.get_sha256(path)
	for name: String in LITERAL_HASHES:
		for extension: String in [".exact.json", ".store.json"]:
			var path: String = FIXTURES + name + extension
			result[path] = FileAccess.get_sha256(path)
	return result

func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if is_instance_valid(game): await _dispose()
	var dir := DirAccess.open(test_root)
	if dir != null:
		for name: String in dir.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	paused = false
	var source_after: Dictionary = _sources()
	_expect(source_after == source_before, "explicit named sources and literal fixtures remain unchanged")
	var report: Dictionary = {"schema_version": 1, "checks": checks, "failures": failures, "rows": rows, "first_failure": first_failure, "complete": complete, "success": complete and failures == 0, "source_before": source_before, "source_after": source_after, "receipts": receipts, "quiet_events": quiet_events, "scope": "Four literal newly executed oldAPI1 native Player+Level units: Standard/oldChallenge entrance+Root warning, opposite TEST current preferences, fresh paused canonical native candidate, Hero-first quiet restore, exact legacy recapture, raw format2 reread, atomic forgery refusal and cleanup. Producer pairs are not CampaignAttempts; no production Shell Continue/Retry, full route, visual, balance or performance credit."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(report_path).get_base_dir())
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: print("A3-L2 legacy report write failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("CINDER_A3_L2_ARRANGEMENT_LEGACY_REPORT path=" + report_path + " sha256=" + FileAccess.get_sha256(report_path))
	print("A3-L2 arrangement legacy: %d checks/%d failures; complete=%s; units=%d" % [checks, failures, str(complete), receipts.size()])
	quit(0 if complete and failures == 0 else 1)
