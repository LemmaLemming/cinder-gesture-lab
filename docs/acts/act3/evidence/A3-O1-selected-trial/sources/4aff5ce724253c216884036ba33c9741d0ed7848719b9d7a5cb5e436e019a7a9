extends "res://tests/acts/act3/pillars_before_time_optional_shell.gd"
## Focused selected O1 construction/format and actual legacy-reader check.
## Reuses immutable genuine Standard entrance/CP1/held ExactJSON packets.
## Their whole original held session is reencoded to a NEW isolated format2
## Store for actual Side Resume/Retry. No original raw Store is claimed.
## Fresh profiles below are zero-clock public Optional entries only. Synthetic
## local dictionaries test pure dispatch, never authenticate historical saves.
## No live gameplay, layout trial, new producer, full route or balance credit.

const Construction = preload("res://scripts/acts/act3/pillars_construction.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const ORIGINAL_ROOT: String = "res://assets/acts/act3/evidence/A3-O1-native/captures/authentic-held"
const OLD_API: String = "act3-pillars-before-time-2"
const NEW_API: String = "act3-pillars-before-time-3"
const CANONICAL_RECIPE: String = "A3-O1/canonical-homes@v1"
const CHALLENGE_RECIPE: String = "A3-O1/challenge-central-southwest@v2"
const OLD_LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route"]
const NEW_LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route", "construction"]
const ORIGINAL_PINS: Dictionary = {
	"checkpoint.native.json": "80cbc80376497b2bdd6bc53af70f602407a5feb1798340cf8f415e0faff98c24",
	"entrance.native.json": "d5fb79d04ab1c6b958769ae91c37beacedfd601da4ba06ee030d0f435c6bb6ab",
	"held.native.json": "2de8d2d6d62bb2131b30a7f43a484b3b3c26983aee36c26878a84ef9591411ad",
	"manifest.json": "8262e3fd7c82ebf90f889999b1f89fb6f388ea5289c0cc311d2a1afd78d40130",
	"registry.native.json": "e181f9ec4dbf4844fa61b0155f43339b11e4e4ff9bbc77b4d27719e05c2913cb",
	"session.native.json": "98035f1aa87c469dde71dcc938e42399b09c298b2da66b39c36e810ed4cd8c51",
	"start-session.native.json": "b9775b24dc7c4816264385edb3c6eb7023c2d754fa26553f46d04b43c823a996",
	"story.native.json": "68e1b84772bcf8feed4457ac8ff4536d702f9d4c4e488038723115e3656c3ec2",
}

var _original: Dictionary = {}
var _catalogue = Difficulty.new()
var _mode: String = ""


func _run() -> void:
	create_timer(180.0, true, false, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "focused constructor/legacy reader bounded180-second watchdog")
			_finish())
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	if not _expect(DisplayServer.get_name() == "headless", "focused construction fixture is headless, with no portrait claim"):
		await _finish(); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not _expect(args == PackedStringArray(["--pure"]) or args == PackedStringArray(["--legacy-reader"]) or args == PackedStringArray(["--fresh-construction"]), "one explicit bounded focused selector only"):
		await _finish(); return
	_mode = args[0]
	if not _read_originals(): await _finish(); return
	if _mode == "--pure":
		scope_complete = _pure()
		await _finish(); return
	node_added.connect(_watch_node)
	if not _prepare_registry(): await _finish(); return
	if _mode == "--legacy-reader": scope_complete = await _legacy_reader()
	else: scope_complete = await _fresh_construction()
	await _finish()


func _read_originals() -> bool:
	for filename: String in ORIGINAL_PINS:
		var path: String = ORIGINAL_ROOT.path_join(filename)
		if not _expect(FileAccess.get_sha256(path) == ORIGINAL_PINS[filename], "immutable known genuine archive byte pin: " + filename): return false
		var decoded: Dictionary = Exact.parse(FileAccess.get_file_as_string(path))
		if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "actual existing ExactJSON decoder reads original archive: " + filename, String(decoded.get("error", ""))): return false
		_original[filename] = (decoded.value as Dictionary).duplicate(true)
	var genuine_session: Dictionary = _original["session.native.json"]
	if not _expect(_same(genuine_session.side_attempt.snapshot, _original["held.native.json"]) and _same(genuine_session.side_attempt.checkpoint, _original["checkpoint.native.json"]) and _same(genuine_session.story.snapshot, _original["story.native.json"]), "unchanged genuine Standard held session joins actual earlier CP1 and protected Story"): return false
	for filename: String in ["entrance.native.json", "checkpoint.native.json", "held.native.json"]:
		var unit: Dictionary = _original[filename]
		var before: PackedByteArray = var_to_bytes(unit)
		var selected: Dictionary = Construction.saved(unit.level.local)
		if not _expect(selected.get("error") == "" and selected.legacy and selected.profile_id == "standard" and selected.recipe_id == CANONICAL_RECIPE and selected.homes == O1.SOURCE_POSITIONS and unit.level.local_snapshot_version == 2 and Codec.keys_error(unit.level.local, OLD_LOCAL_KEYS).is_empty() and unit.level.local.api_revision == OLD_API and before == var_to_bytes(unit), "pure preflight accepts unchanged genuine old six-key Standard packet without mutation: " + filename, String(selected.get("error", ""))): return false
	return true


func _synthetic_new(profile_id: String, recipe_id: String) -> Dictionary:
	# Format-only synthetic packet. Its source/Player history is NOT claimed as
	# genuine Challenge or a complete restorable aggregate.
	var local: Dictionary = (_original["entrance.native.json"].level.local as Dictionary).duplicate(true)
	local.api_revision = NEW_API
	local.schema_version = 2
	local.scheduler.profile = _catalogue.profile(profile_id)
	local["construction"] = {"api_revision": "act3-pillars-construction-1", "schema_version": 1, "profile": _catalogue.profile(profile_id), "recipe_id": recipe_id}
	return local


func _pure_accept(local: Dictionary, legacy: bool, profile_id: String, recipe_id: String, label: String) -> bool:
	var before: PackedByteArray = var_to_bytes(local)
	var selected: Dictionary = Construction.saved(local)
	return _expect(selected.get("error") == "" and selected.legacy == legacy and selected.profile_id == profile_id and selected.recipe_id == recipe_id and before == var_to_bytes(local), label, String(selected.get("error", "")))


func _pure_refuse(local: Dictionary, label: String) -> bool:
	var before: PackedByteArray = var_to_bytes(local)
	var selected: Dictionary = Construction.saved(local)
	return _expect(selected.get("error") is String and not String(selected.error).is_empty() and before == var_to_bytes(local), "closed pure refusal preserves input: " + label)


func _pure() -> bool:
	if not _expect(_catalogue.last_error.is_empty(), "actual immutable canonical Difficulty catalogue is readable", _catalogue.last_error): return false
	for profile_id: String in ["assisted", "standard", "challenge"]:
		var selected: Dictionary = Construction.fresh(profile_id)
		var expected_recipe: String = CHALLENGE_RECIPE if profile_id == "challenge" else CANONICAL_RECIPE
		var expected_homes: Dictionary = O1.SOURCE_POSITIONS.duplicate(true)
		if profile_id == "challenge": expected_homes["o1-central-stalker"] = Vector3(-3, 0.1, 1)
		if not _expect(selected.get("error") == "" and not selected.legacy and selected.profile_id == profile_id and selected.recipe_id == expected_recipe and _same(selected.profile, _catalogue.profile(profile_id)) and selected.homes == expected_homes, "fresh canonical profile selects exactly one finite complete home map: " + profile_id, String(selected.get("error", ""))): return false
		var untouched: Dictionary = selected.duplicate(true)
		selected.homes["o1-central-stalker"] = Vector3(99, 0.1, 99)
		selected.profile.name = "caller mutation"
		selected.construction.profile.name = "descriptor mutation"
		if not _expect(var_to_bytes(Construction.fresh(profile_id)) == var_to_bytes(untouched), "fresh caller mutations cannot alter later canonical construction: " + profile_id): return false
		if not _pure_accept(_synthetic_new(profile_id, expected_recipe), false, profile_id, expected_recipe, "synthetic new format accepts selected fresh profile/recipe: " + profile_id): return false
	# Root amendment: saved canonical v1 is independently valid for Challenge.
	if not _pure_accept(_synthetic_new("challenge", CANONICAL_RECIPE), false, "challenge", CANONICAL_RECIPE, "explicit saved Challenge/canonical-v1 is valid independently of fresh mapping"): return false
	var old: Dictionary = (_original["entrance.native.json"].level.local as Dictionary).duplicate(true)
	old.scheduler.profile = _catalogue.profile("challenge")
	if not _pure_accept(old, true, "challenge", CANONICAL_RECIPE, "synthetic old Challenge dispatch remains old canonical; no authentic historical packet claim"): return false
	for key: String in OLD_LOCAL_KEYS:
		var missing_old: Dictionary = old.duplicate(true); missing_old.erase(key)
		if not _pure_refuse(missing_old, "missing literal old local key " + key): return false
	old.schema_version = 1.0
	old.scheduler.profile.reserved_threat_budget = int(old.scheduler.profile.reserved_threat_budget)
	var legacy_typed: PackedByteArray = var_to_bytes(old.scheduler.profile)
	var legacy_result: Dictionary = Construction.saved(old)
	if not _expect(legacy_result.get("error") == "" and legacy_typed == var_to_bytes(legacy_result.profile) and typeof(legacy_result.profile.reserved_threat_budget) == TYPE_INT, "legacy existing numeric acceptance retains validated saved profile without normalization", String(legacy_result.get("error", ""))): return false
	if not _expect(not String(Construction.fresh("unknown").get("error", "")).is_empty(), "unknown fresh profile refuses"): return false
	var base: Dictionary = _synthetic_new("challenge", CHALLENGE_RECIPE)
	for key: String in NEW_LOCAL_KEYS:
		var missing: Dictionary = base.duplicate(true); missing.erase(key)
		if not _pure_refuse(missing, "missing new local key " + key): return false
	for key: String in ["api_revision", "schema_version", "profile", "recipe_id"]:
		var missing: Dictionary = base.duplicate(true); missing.construction.erase(key)
		if not _pure_refuse(missing, "missing descriptor key " + key): return false
	var bad: Dictionary = base.duplicate(true); bad["extra"] = true
	if not _pure_refuse(bad, "extra outer local key"): return false
	bad = base.duplicate(true); bad.construction["extra"] = true
	if not _pure_refuse(bad, "extra descriptor key"): return false
	bad = base.duplicate(true); bad.api_revision = OLD_API; bad.schema_version = 1
	if not _pure_refuse(bad, "old API with extra new descriptor hybrid"): return false
	bad = base.duplicate(true); bad.api_revision = "unknown"
	if not _pure_refuse(bad, "unknown API"): return false
	bad = base.duplicate(true); bad.schema_version = 2.0
	if not _pure_refuse(bad, "new outer schema float instead of int"): return false
	bad = base.duplicate(true); bad.construction.schema_version = 1.0
	if not _pure_refuse(bad, "descriptor schema float instead of int"): return false
	bad = base.duplicate(true); bad.construction.api_revision = "unknown"
	if not _pure_refuse(bad, "unknown descriptor API"): return false
	bad = base.duplicate(true); bad.construction.recipe_id = "unknown"
	if not _pure_refuse(bad, "unknown finite recipe"): return false
	for profile_id: String in ["assisted", "standard"]:
		if not _pure_refuse(_synthetic_new(profile_id, CHALLENGE_RECIPE), "Challenge-only v2 recipe under " + profile_id): return false
	for side: String in ["scheduler", "construction"]:
		for key: String in _catalogue.profile("challenge"):
			bad = base.duplicate(true)
			bad[side].profile.erase(key)
			if not _pure_refuse(bad, "missing full typed profile field " + side + "/" + key): return false
		bad = base.duplicate(true); bad[side].profile["extra"] = true
		if not _pure_refuse(bad, "extra full profile key " + side): return false
		bad = base.duplicate(true); bad[side].profile.reserved_threat_budget = int(bad[side].profile.reserved_threat_budget)
		if not _pure_refuse(bad, "new catalogue float budget cannot be int " + side): return false
		bad = base.duplicate(true); bad[side].profile.name = "renamed"
		if not _pure_refuse(bad, "full profile name drift " + side): return false
		bad = base.duplicate(true); bad[side].profile.raw_damage_multiplier = NAN
		if not _pure_refuse(bad, "nonfinite profile number " + side): return false
	bad = base.duplicate(true); bad.scheduler.profile = _catalogue.profile("standard")
	if not _pure_refuse(bad, "saved Scheduler and construction full profiles disagree"): return false
	bad = base.duplicate(true); bad.construction.profile = "challenge"
	if not _pure_refuse(bad, "profile ID alone is not full authority"): return false
	bad = base.duplicate(true)
	var recipe_value: String = bad.construction.recipe_id
	bad.construction.erase("recipe_id"); bad.construction[&"recipe_id"] = recipe_value
	if not _pure_refuse(bad, "StringName descriptor key instead of exact String"): return false
	var copied_input: Dictionary = base.duplicate(true)
	var copied_result: Dictionary = Construction.saved(copied_input)
	var expected_result: Dictionary = copied_result.duplicate(true)
	copied_input.construction.profile.name = "input mutation"
	copied_input.scheduler.profile.name = "input scheduler mutation"
	if not _expect(var_to_bytes(copied_result) == var_to_bytes(expected_result), "saved selection owns defensive copies independent of input"): return false
	return _expect(true, "complete finite constructor/format matrix; all historical Challenge examples above are disclosed synthetic local dispatch only")


func _prepare_registry() -> bool:
	var parsed: Variant = JSON.parse_string(canonical_bytes)
	if not _expect(parsed is Dictionary, "current canonical registry is readable without changing it"): return false
	raw = parsed.duplicate(true)
	for row: Dictionary in raw.levels:
		if row.id == "A3-O1":
			row.scene_path = OPTIONAL_PATH
			row.readiness = "accepted"
			row.accepted_commit = "a".repeat(40) # Existing disclosed TEST readiness only.
			row.api_revision = Registry.API_REVISION
	var registry = Registry.new(raw)
	return _expect(registry.last_error.is_empty() and registry.scene_error("A3-O1").is_empty(), "current TEST readiness preserves actual Optional identity/parent and all campaign rows", registry.last_error)


func _stage_session(session: Dictionary) -> bool:
	if not _expect(not is_instance_valid(production), "isolated Store staging has no live recipient"): return false
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = isolated + filename
		if FileAccess.file_exists(path) and not _expect(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK, "remove only this fixture's disposable user file " + filename): return false
	var model = Attempts.new(Registry.new(raw))
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(session).is_empty() and writer.write_payload(session), "original genuine native exact session is reencoded into new isolated format2 Store without gameplay edits", model.last_error + "; " + writer.last_error): return false
	return _disk(session)


func _future_preference(profile_id: String) -> bool:
	var before: Dictionary = production.attempts.state()
	var before_snapshot: Dictionary = production.capture_campaign_snapshot() if is_instance_valid(production.active_level) else {}
	production.menu.show_settings()
	var selector: OptionButton = production.menu.find_child("DifficultySelector", true, false) as OptionButton
	if not _expect(is_instance_valid(selector), "actual public Settings exposes difficulty selector"): return false
	var selected: int = -1
	for index: int in range(selector.item_count):
		if selector.get_item_metadata(index) == profile_id: selected = index
	if not _expect(selected >= 0, "actual canonical public future profile option " + profile_id): return false
	selector.select(selected); selector.item_selected.emit(selected)
	var reader = Store.new(isolated + "preferences.json")
	if not _expect(production.get_difficulty_preference() == profile_id and _same(reader.read_payload(), {"schema_version": 1, "profile_id": profile_id}) and _same(production.attempts.state(), before), "public preference persists future selection without touching genuine saved session"): return false
	return _expect(before_snapshot.is_empty() or _same(production.capture_campaign_snapshot(), before_snapshot), "future preference does not remap a currently installed unit")


func _actual_homes(expected: Dictionary, label: String) -> bool:
	var level: CinderLevel = production.active_level
	for id: String in O1.SOURCE_IDS:
		var marker: Marker3D = level.get_node_or_null("EncounterHomes/" + id.replace("-", "_")) as Marker3D
		var source: Node3D = level.get("sources")[id] as Node3D
		if not _expect(is_instance_valid(marker) and is_instance_valid(source) and marker.position == expected[id], label + ": selected real Marker home " + id): return false
		var local: Dictionary = production.capture_campaign_snapshot().level.local
		if not local.route.awakenings.has(id) and not _expect(source.position == expected[id] and not source.is_physics_processing(), label + ": still-dormant native source remains at selected home " + id): return false
	return true


func _quiet_unit(unit: Dictionary, session: Dictionary) -> bool:
	if not _quiet_selected(): return false
	var ids: Dictionary = _native_ids()
	var input: PackedByteArray = var_to_bytes(production.get_input_observation_state())
	var events: PackedByteArray = var_to_bytes(receiver_events)
	for _frame: int in range(3): await process_frame
	return _expect(paused and _same(production.capture_campaign_snapshot(), unit) and _same(production.attempts.state(), session) and not ids.is_empty() and var_to_bytes(_native_ids()) == var_to_bytes(ids) and input == var_to_bytes(production.get_input_observation_state()) and events == var_to_bytes(receiver_events), "ordinary paused frames preserve whole native unit/profile/history/IDs/input/events/session")


func _once_guard() -> bool:
	var unit: Dictionary = production.capture_campaign_snapshot()
	var selected: Dictionary = production.active_level.call("selected_construction")
	var native_map: Dictionary = production.active_level.call("selected_source_positions")
	var ids: Dictionary = _native_ids()
	var events: PackedByteArray = var_to_bytes(receiver_events)
	var refusal: String = production.active_level.call("_configure_sources", selected)
	if not _expect(refusal == "Pillars selected native construction may only configure once" and _same(production.capture_campaign_snapshot(), unit) and not ids.is_empty() and var_to_bytes(_native_ids()) == var_to_bytes(ids) and events == var_to_bytes(receiver_events), "repeat selected constructor refuses before any second native configure/begin/history mutation", refusal): return false
	var expected: PackedByteArray = var_to_bytes(selected)
	selected.homes["o1-central-stalker"] = Vector3(99, 0.1, 99)
	selected.profile.name = "caller mutation"
	native_map["o1-central-stalker"] = Vector3(99, 0.1, 99)
	return _expect(expected == var_to_bytes(production.active_level.call("selected_construction")) and _same(production.capture_campaign_snapshot(), unit), "public selected constructor/map views are defensive copies with no native mutation")


func _refuse_live_level(bad: Dictionary, label: String) -> bool:
	var unit: Dictionary = production.capture_campaign_snapshot()
	var session: Dictionary = production.attempts.state()
	var ids: Dictionary = _native_ids()
	var input: PackedByteArray = var_to_bytes(production.get_input_observation_state())
	var events: PackedByteArray = var_to_bytes(receiver_events)
	var primary: String = FileAccess.get_sha256(isolated + "campaign.json")
	if not _expect(not production.active_level.restore_state(bad) and not production.active_level.last_snapshot_error.is_empty(), "actual entered native level refuses " + label): return false
	return _expect(_same(production.capture_campaign_snapshot(), unit) and _same(production.attempts.state(), session) and not ids.is_empty() and var_to_bytes(_native_ids()) == var_to_bytes(ids) and input == var_to_bytes(production.get_input_observation_state()) and events == var_to_bytes(receiver_events) and FileAccess.get_sha256(isolated + "campaign.json") == primary, "actual native refusal preserves donor full packet/IDs/leases/input/optics/session/disk/events: " + label)


func _legacy_reader() -> bool:
	var original_session: Dictionary = _original["session.native.json"]
	held = _original["held.native.json"]
	checkpoint = _original["checkpoint.native.json"]
	protected = _original["story.native.json"]
	if not _stage_session(original_session) or not await _new_shell(original_session) or not _future_preference("challenge"): return false
	production.menu.resume_requested.emit() # Public Title Resume Side; not Continue Story.
	if not await _wait_installed("A3-O1", "resume", held): return false
	if not _installed(held) or not _actual_homes(O1.SOURCE_POSITIONS, "genuine old Standard held recipient") or not await _quiet_unit(held, original_session) or not _once_guard(): return false
	var actual: Dictionary = production.capture_campaign_snapshot()
	if not _expect(actual.level.local_snapshot_version == 2 and Codec.keys_error(actual.level.local, OLD_LOCAL_KEYS).is_empty() and actual.level.local.api_revision == OLD_API and _same(actual.level.local.scheduler.profile, held.level.local.scheduler.profile) and actual.level.local.scheduler.encounter_id == O1.ENCOUNTER_ID and actual.level.local.scheduler.profile.size() == 8 and _same(_held_receipt(), _original["manifest.json"].held_receipt), "actual existing legacy reader recaptures literal six-key writer/full Standard profile/real warning receipt under future Challenge"): return false
	# A malformed live restore must fail before mutating the installed donor.
	var bad: Dictionary = actual.level.duplicate(true)
	bad.local["construction"] = {"recipe_id": CHALLENGE_RECIPE}
	if not _refuse_live_level(bad, "old six-key/new descriptor hybrid"): return false
	bad = actual.level.duplicate(true); bad.local.scheduler.encounter_id = ""; bad.local.scheduler.profile = {}
	if not _refuse_live_level(bad, "empty-ended Scheduler as resumable O1"): return false
	var old_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_refs)
	var old_ids: Dictionary = _native_ids()
	receiver_events.clear()
	production.menu.retry_requested.emit()
	if not await _wait_installed("A3-O1", "resume", checkpoint, old_ids): return false
	var retried: Dictionary = original_session.duplicate(true)
	retried.side_attempt.snapshot = checkpoint.duplicate(true)
	if not _installed(checkpoint) or not _distinct(old_ids) or not await _released(old_refs, "genuine earlier Optional CP1 Retry retires all held native bindings") or not _actual_homes(O1.SOURCE_POSITIONS, "genuine earlier old Standard CP1 recipient") or not await _quiet_unit(checkpoint, retried): return false
	if not _expect(_same(production.attempts.state().story, original_session.story) and _same(production.attempts.state().side_attempt.checkpoint, checkpoint) and production.get_difficulty_preference() == "challenge" and Codec.keys_error(production.capture_campaign_snapshot().level.local, OLD_LOCAL_KEYS).is_empty(), "actual Retry retains literal old saved Standard branch/earlier CP1/protected Story despite future Challenge"): return false
	return _disk(retried) and _verify_originals()


func _fresh_construction() -> bool:
	var seed: Dictionary = _original["start-session.native.json"]
	protected = _original["story.native.json"]
	for profile_id: String in ["assisted", "standard", "challenge"]:
		if not _stage_session(seed) or not await _new_shell(seed) or not _future_preference(profile_id): return false
		production.menu.continue_story_requested.emit()
		if not await _wait_installed(STORY_ID, "resume", protected): return false
		if not _installed(protected): return false
		var old_ids: Dictionary = _core_ids()
		production.menu.optional_requested.emit("A3-O1")
		if not await _wait_installed("A3-O1", "resume", {}, old_ids): return false
		var unit: Dictionary = production.capture_campaign_snapshot()
		var selected: Dictionary = Construction.fresh(profile_id)
		if not _installed(unit) or not _actual_homes(selected.homes, "actual fresh " + profile_id): return false
		if not _expect(unit.level.local_snapshot_version == 2 and Codec.keys_error(unit.level.local, NEW_LOCAL_KEYS).is_empty() and unit.level.local.api_revision == NEW_API and typeof(unit.level.local.schema_version) == TYPE_INT and unit.level.local.schema_version == 2 and _same(unit.level.local.construction, selected.construction) and _same(unit.level.local.scheduler.profile, selected.profile) and unit.shell.difficulty_at_entry == profile_id and unit.level.local.scheduler.clock_s == 0.0 and unit.player.world_actions.clock_s == 0.0 and unit.player.world_actions.history.is_empty() and unit.level.local.route.awakenings.is_empty() and unit.level.local.route.collections.is_empty(), "public zero-clock fresh Optional uses frozen closed writer/full profile/home recipe without gameplay seeds: " + profile_id): return false
		if not await _quiet_unit(unit, production.attempts.state()) or not _once_guard(): return false
		var bad: Dictionary = unit.level.duplicate(true)
		bad.local.sources["o1-central-stalker"].position[0] += 0.25
		if not _refuse_live_level(bad, "partial selected dormant source home drift under " + profile_id): return false
		if not await _dispose_shell(): return false
	return _verify_originals()


func _verify_originals() -> bool:
	for filename: String in ORIGINAL_PINS:
		if not _expect(FileAccess.get_sha256(ORIGINAL_ROOT.path_join(filename)) == ORIGINAL_PINS[filename], "immutable original archive remains exact after reader exercise: " + filename): return false
	return true


func _finish() -> void:
	if finished: return
	finished = true
	await _dispose_shell()
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes, "current canonical registry bytes unchanged")
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = isolated + filename
		if FileAccess.file_exists(path):
			_expect(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK, "normal cleanup only isolated disposable file " + filename)
	AudioServer.set_bus_layout(old_audio)
	Engine.max_fps = old_fps
	print("O1 focused construction: %d checks/%d failures; scope_complete=%s; selector=%s; genuine Standard archive decoder/constructor scope and explicit selected branch only; new isolated Store reencoding is not original raw Store custody; no runtime response/layout safety/portrait/full-route/new producer credit." % [checks, failures, str(scope_complete), _mode])
	quit(0 if failures == 0 and scope_complete else 1)
