extends SceneTree
## Focused literal newly executed original Weybridge15-key Player+Level units; these are not campaign sessions.
## TEST Main overrides only current preference. Its ordinary preview is disposed;
## a fresh canonical L2 candidate uses the real public paused-construction API.
## No actor state, native geometry, clock, HP or saved unit is rewritten to pass.

const MainScene = preload("res://scenes/main.tscn")
const LevelScene = preload("res://scenes/acts/act2/a2_l2.tscn")
const Parent = preload("res://scripts/acts/act2/weybridge.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const LEVEL_PATH: String = "res://scenes/acts/act2/a2_l2.tscn"
const FIXTURES: String = "res://tests/acts/act2/fixtures/a2_l2_difficulty_legacy/"
const PRODUCER_REPORT_SHA: String = "12ef54eaefdddcb9ccc2f750ef8b2853a0cd6fd502603006f6e8cd45ba29d403"
const SOURCE_ID: String = "village_scout"
const LITERAL_HASHES: Dictionary = {
	"standard-entrance": ["a4f809abac729e5eed784a90c1d8b15c8868a9c5151f33f5469ba7806ec3acb5", "a7882cca925cad271eec660d716fdc3c59642fede81b53b3776be42750f40a3e"],
	"standard-ray-warning": ["99374128667048cf66d6ed9febd29f8a95a7162c7b0562fd1a51e2c58cd3ef0f", "80243207fca5bdd931fc168914dce0ef951edc9547551be7873c65a6268c7975"],
	"challenge-entrance": ["c746dbfa79cfe52dd33fd9aa39edc4c9df15844bd0aba48beed8efb73c2a5748", "e6f880a3ceb31ae9a5e3ccf9293f1c4346ee13ee274823c4c6ebc8a3b48e1f4e"],
	"challenge-ray-warning": ["520062798f964084b49c4102e7210408e50ce4697812f442e74a5d1a3da623de", "bd96e3c526e58daaedcc346453ba04803e3a2e22fb2c8f7cf4e259e52ff5ebb4"],
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
var prior_native_ids: Array[int] = []
var source_before: Dictionary = {}
var test_root: String
var report_path: String
var complete: bool = false
var finishing: bool = false

func _initialize() -> void:
	test_root = "user://test-a2-l2-arrangement-legacy-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = OS.get_environment("CINDER_A2_L2_ARRANGEMENT_LEGACY_REPORT")
	if report_path.is_empty(): report_path = test_root + "report.json"
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
	if not _expect(failures == 0 and provenance is Dictionary and provenance.get("packets") is Array and provenance.packets.size() == 4 and provenance.get("report") is Dictionary and provenance.report.get("sha256") == PRODUCER_REPORT_SHA, "four literal executed-original15-key units retain native producer provenance"):
		await _finish(); return
	for record: Dictionary in provenance.packets:
		if not await _exercise(record): await _finish(); return
	complete = true
	await _finish()

func _exercise(record: Dictionary) -> bool:
	var name: String = String(record.profile) + "-" + String(record.stage)
	var wire_path: String = FIXTURES + name + ".exact.json"
	var raw_path: String = FIXTURES + name + ".store.json"
	if not _expect(LITERAL_HASHES.has(name) and FileAccess.get_sha256(wire_path) == LITERAL_HASHES[name][0] and FileAccess.get_sha256(raw_path) == LITERAL_HASHES[name][1] and record.exact.sha256 == LITERAL_HASHES[name][0] and record.raw_store.sha256 == LITERAL_HASHES[name][1], "original exact/raw Store byte hashes: " + name): return false
	var wire: String = FileAccess.get_file_as_string(wire_path)
	var parsed: Dictionary = Exact.parse(wire)
	if not _expect(parsed.get("accepted") == true and parsed.get("value") is Dictionary, "literal native wire decodes without reencoding: " + name): return false
	var unit: Dictionary = parsed.value
	if not _expect(_legacy_shape(unit, String(record.profile)) and Exact.stringify(unit) == wire, "whole original15-key pair retains exact scalar types/bits: " + name): return false
	var opposite: String = "challenge" if record.profile == "standard" else "standard"
	if not await _open(unit, opposite): return false
	if not _expect(hero.snapshot_error(unit.player).is_empty() and _pair_error(unit).is_empty(), "fresh candidate independently prevalidates entire saved Hero and Level: " + name, hero.last_snapshot_error + "; " + _pair_error(unit)): return false
	var identities: Dictionary = _identities()
	var unique: Dictionary = {}
	var fresh_ids: bool = identities.size() == 19
	for native_id: Variant in identities.values():
		fresh_ids = fresh_ids and native_id is int and native_id != 0 and not unique.has(native_id) and not prior_native_ids.has(native_id)
		unique[native_id] = true
	if not _expect(fresh_ids, "actual valid nonzero independent native identities; no positive-ID assumption"): return false
	for native_id: int in identities.values(): prior_native_ids.append(native_id)
	if not _expect(hero.restore_state(unit.player), "actual shared Hero restores first: " + name, hero.last_snapshot_error): return false
	if not _expect(level.restore_state(unit.level), "actual Level quietly restores after Hero: " + name, level.last_snapshot_error): return false
	if not _expect(paused and level.is_restore_candidate() and level.hero == hero and level.effects == game.get("fx") and level.shared_shell == game and _identities() == identities and quiet_events.is_empty() and _wire() == wire, "exact full legacy recapture and native recipient identities remain quiet: " + name, level.last_snapshot_error): return false
	if not _expect(game.call("get_difficulty_preference") == opposite and scheduler.encounter_profile().id == record.profile and _legacy_shape({"player": hero.snapshot_state(), "level": level.snapshot_state()}, String(record.profile)), "opposite current preference cannot inject new18 receipt or remap saved original arrangement/profile: " + name): return false
	if not _expect(unit.level.local.sequence.stage_index == 0 and unit.level.local.sequence.defeated_ids.is_empty() and unit.level.local.sequence.completed_feet.is_empty() and unit.level.local.sequence.crossed_contacts.is_empty() and unit.level.progress.checkpoint_id.is_empty(), "literal native first-stage history contains no earned route/clear"): return false
	if record.stage == "entrance":
		if not _expect(unit.level.local.scheduler.reservations.is_empty(), "genuine old paused constructor entrance remains free of leases; no settled-floor claim"): return false
	else:
		var state: Dictionary = (level.get("_exchange") as Node).call("state", SOURCE_ID)
		if not _expect(state.status == "running" and state.phase == "warning" and state.armed == false and unit.level.local.scheduler.reservations.size() == 1 and unit.level.local.scheduler.reservations[0].adapter.locked == false, "genuine old first Scout unarmed tracking warning/lease remains exact"): return false
	var disk_path: String = test_root + name + ".json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))
	var file := FileAccess.open(disk_path, FileAccess.WRITE)
	if not _expect(file != null, "unique TEST raw Store destination opens"): return false
	file.store_buffer(FileAccess.get_file_as_bytes(raw_path)); file.close()
	var store: CinderSaveStore = Store.new(disk_path)
	store.payload_validator = _pair_error
	var reread: Dictionary = store.read_payload()
	if not _expect(not store.loaded_backup and store.generation == 1 and Exact.stringify(reread) == wire and FileAccess.get_sha256(disk_path) == LITERAL_HASHES[name][1], "independent actual format2 Store reread retains original raw bytes and complete native pair: " + name, store.last_error): return false
	for kind: String in ["recipe", "source-type", "placement", "prefix", "future-death", "geometry", "profile"]:
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
	quiet_events.clear()
	level.completion_requested.connect(func(_id: String, _event: String) -> void: quiet_events.append("completion"))
	level.contact_exit_requested.connect(func(_id: String, _event: String) -> void: quiet_events.append("exit"))
	level.checkpoint_requested.connect(func(_id: String, _event: String, _kind: String) -> void: quiet_events.append("checkpoint"))
	hero.died.connect(func() -> void: quiet_events.append("Hero death"))
	hero.fired.connect(func(_kind: String) -> void: quiet_events.append("Hero fire"))
	hero.equipment_changed.connect(func(_id: String) -> void: quiet_events.append("Hero equipment"))
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: quiet_events.append("Hero action"))
	await process_frame; await process_frame
	if finishing: return false
	if not _expect(paused and preview_ref.get_ref() == null and level.scene_file_path == LEVEL_PATH and level.get_script() == Parent and level.contract_error().is_empty() and level.restore_candidate_construction_required(), "fresh canonical Weybridge floor registered paused; original preview freed", level.contract_error()): return false
	if not _expect(level.enter_restore_candidate(hero, game.get("fx"), game, unit.level, unit.player), "public fresh paused construction consumes saved old15 layout before native configure", level.last_snapshot_error): return false
	scheduler = level.get("_scheduler") as CinderThreatScheduler
	if not _expect(scheduler != null and (level.get("_actors") as Dictionary).size() == 6 and (level.get("_mechanisms") as Dictionary).size() == 7, "fresh saved-profile constructor produced six actors and seven native mechanisms once"): return false
	for actor: Node in (level.get("_actors") as Dictionary).values():
		actor.connect("defeated", func(_id: String) -> void: quiet_events.append("native source defeat"))
	return true

func _legacy_shape(unit: Dictionary, saved_profile: String) -> bool:
	if unit.size() != 2 or not unit.get("player") is Dictionary or not unit.get("level") is Dictionary or not unit.level.get("local") is Dictionary: return false
	var local: Dictionary = unit.level.local
	return unit.level.local_snapshot_version is int and unit.level.local_snapshot_version == 1 and local.size() == 15 and not local.has("api_revision") and not local.has("schema_version") and not local.has("arrangement") and local.profile_id == saved_profile and local.scheduler.profile.id == saved_profile and local.handlers.size() == 3 and local.rays.actors.size() == 3 and local.mechanisms.size() == 7


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
		"recipe": local["arrangement"] = {"recipe_id": "TEST-unearned-new18-recipe"}
		"source-type": local.handlers.shelter_handler.api_revision = "foreign-handler-source"
		"placement": local.handlers.shelter_handler.root_position[0] += 0.25
		"prefix": local.sequence.defeated_ids.append("village_scout")
		"future-death":
			local.handlers.shelter_handler.hp = 0.0
			local.handlers.shelter_handler.phase = "defeated"
			local.handlers.shelter_handler.phase_progress = 1.0
		"geometry": local.mechanisms.tool_shelter_handler.configuration.geometry.from[0] += 0.25
		"profile": local.profile_id = "assisted"
		"lease-geometry": local.scheduler.reservations[0].geometry.from[0] += 0.25
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
	result["exchange"] = level.get("_exchange").get_instance_id()
	for id: String in level.get("_actors"):
		result["actor/" + id] = (level.get("_actors") as Dictionary)[id].get_instance_id()
	for id: String in level.get("_mechanisms"):
		result["mechanism/" + id] = (level.get("_mechanisms") as Dictionary)[id].get_instance_id()

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
		print("FAIL A2-L2 arrangement legacy: " + label + "; " + detail)
	return ok

func _sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [get_script().resource_path, FIXTURES + "PROVENANCE.json", "res://scripts/game.gd", "res://scripts/player.gd", "res://scripts/campaign/level.gd", "res://scripts/campaign/save_store.gd", "res://scripts/campaign/exact_json.gd", "res://scripts/acts/act2/weybridge.gd", "res://scripts/acts/act2/ray_scout_actor.gd", "res://scripts/acts/act2/ray_scout_exchange.gd", "res://scripts/acts/act2/salvage_handler_actor.gd", "res://scripts/combat/lane_mechanism.gd", "res://data/campaign/act2/a2_l2_difficulty_arrangements.json", LEVEL_PATH, "res://scenes/main.tscn"]:
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
	paused = false
	var source_after: Dictionary = _sources()
	_expect(source_after == source_before, "explicit named sources and literal fixtures remain unchanged")
	var report: Dictionary = {"schema_version": 1, "checks": checks, "failures": failures, "rows": rows, "first_failure": first_failure, "complete": complete, "success": complete and failures == 0, "source_before": source_before, "source_after": source_after, "receipts": receipts, "quiet_events": quiet_events, "scope": "Four literal newly executed original15-key native Player+Level units: Standard/oldChallenge constructor entrance+first unarmed Scout warning, opposite TEST current preferences, saved-profile fresh paused canonical native candidate, Hero-first quiet restore, exact legacy recapture, raw format2 reread, atomic forgery refusal and cleanup. Producer pairs are not CampaignAttempts; no production Shell Continue/Retry, full route, visual, balance or performance credit."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(report_path).get_base_dir())
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: print("A2-L2 legacy report write failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("CINDER_A2_L2_ARRANGEMENT_LEGACY_REPORT path=" + report_path + " sha256=" + FileAccess.get_sha256(report_path))
	print("A2-L2 arrangement legacy: %d checks/%d failures; complete=%s; units=%d" % [checks, failures, str(complete), receipts.size()])
	quit(0 if complete and failures == 0 else 1)
