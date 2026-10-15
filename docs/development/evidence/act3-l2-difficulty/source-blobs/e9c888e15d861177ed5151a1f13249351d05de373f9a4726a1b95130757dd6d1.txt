extends SceneTree
## Pure authored selection/construction checks only. No native world or packet
## is fabricated as gameplay evidence; Root runs native/save/portrait separately.

const Forest = preload("res://scripts/acts/act3/living_forest_level.gd")
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")

var checks: int = 0
var failures: int = 0
var rows: Array[Dictionary] = []
var first_failure: Dictionary = {}
var complete: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	var row: Dictionary = {"check": checks, "ok": ok, "label": label}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
		push_error("FAIL Forest arrangement pure: " + label)
	return ok


func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Forest.ENCOUNTER_DATA))
	if not _expect(parsed is Dictionary and parsed.get("difficulty_arrangements") is Dictionary, "actual authored definition opens"):
		_finish(); return
	var definition: Dictionary = parsed.difficulty_arrangements
	var original_definition: String = Exact.stringify(definition)
	if not _expect(Forest.arrangement_definition_error(definition).is_empty(), "approved immutable recipes validate"):
		_finish(); return
	var selector := Arrangement.new(definition)
	var standard: Dictionary = selector.select_fresh("standard")
	var challenge: Dictionary = selector.select_fresh("challenge")
	if not _expect(not standard.is_empty() and not challenge.is_empty(), "fresh profiles select actual authored recipes"):
		_finish(); return
	var original_challenge: String = Exact.stringify(challenge)
	var standard_layout: Dictionary = Forest.arrangement_layout(standard, definition)
	var challenge_layout: Dictionary = Forest.arrangement_layout(challenge, definition)
	if not _expect(standard_layout.error.is_empty() and challenge_layout.error.is_empty(), "complete source-slot maps resolve"):
		_finish(); return
	_expect(standard.recipe_id == "A3-L2/standard-canonical@v1" and standard.order == Forest.SOURCE_IDS and standard_layout.entries == Forest.SOURCE_ENTRIES and standard_layout.starts == Forest.SOURCE_POSITIONS, "Standard actual mapping is the exact prior canonical reference")
	_expect(challenge.recipe_id == Forest.CHALLENGE_RECIPE and challenge_layout.entries["l2-priority-stalker"] == 2 and challenge_layout.starts["l2-priority-stalker"] == Vector3(1.1, 0.1, 8), "Challenge puts existing mobile Stalker at fixed-base trunk court with native height")
	_expect(challenge_layout.entries["l2-trunk-root"] == 3 and challenge_layout.starts["l2-trunk-root"] == Vector3(-1.3, 0, -4) and challenge_layout.starts["l2-priority-root"] == Vector3(1.2, 0, -4.5), "Challenge pairs original fixed Roots across priority court at ground height")
	for id: String in Forest.SOURCE_IDS:
		if id in ["l2-priority-stalker", "l2-trunk-root"]: continue
		_expect(challenge_layout.entries[id] == Forest.SOURCE_ENTRIES[id] and challenge_layout.starts[id] == Forest.SOURCE_POSITIONS[id], "other authored source retains its exact slot: " + id)
	_expect(Forest.ENTRY_IDS == ["vast-trunks", "root-promise", "trunk-court", "priority-court", "watched-clearing", "canopy-slit"] and Forest.ENTRY_Z == [38.0, 26.0, 14.0, 1.0, -15.0, -31.0], "spatial entries remain the canonical prefix, not the unit permutation")

	# These skeletal locals test ONLY closed constructor receipts. Empty actors,
	# routes and scenery are intentionally not claimed as valid native saves.
	var local: Dictionary = _local("challenge", challenge)
	var before_local: String = Exact.stringify(local)
	var selected: Dictionary = Forest.arrangement_constructor(local, definition)
	_expect(selected.error.is_empty() and not selected.legacy and selected.descriptor == challenge and selected.entries == challenge_layout.entries, "new inner2 constructor consumes the saved selected recipe")
	var remapped: Dictionary = definition.duplicate(true)
	remapped.current.challenge = Forest.LEGACY_RECIPE_IDS.challenge
	var next_selector := Arrangement.new(remapped)
	var next_fresh: Dictionary = next_selector.select_fresh("challenge")
	var retained: Dictionary = Forest.arrangement_constructor(local, remapped)
	_expect(Forest.arrangement_definition_error(remapped).is_empty() and next_fresh.recipe_id == Forest.LEGACY_RECIPE_IDS.challenge and next_fresh.order == Forest.SOURCE_IDS, "changed current mapping affects a fresh selection")
	_expect(retained.error.is_empty() and retained.descriptor == challenge and retained.starts == challenge_layout.starts, "saved versioned Challenge construction ignores today's current mapping")
	for profile: String in ["assisted", "standard", "challenge"]:
		var legacy: Dictionary = _local(profile)
		var legacy_before: String = Exact.stringify(legacy)
		var old: Dictionary = Forest.arrangement_constructor(legacy, definition)
		_expect(old.error.is_empty() and old.legacy and old.descriptor.recipe_id == Forest.LEGACY_RECIPE_IDS[profile] and old.entries == Forest.SOURCE_ENTRIES and old.starts == Forest.SOURCE_POSITIONS and not legacy.has("arrangement") and Exact.stringify(legacy) == legacy_before, "legacy inner1 uses canonical bindings without receipt injection: " + profile)

	var round_trip: Variant = JSON.parse_string(JSON.stringify(local))
	var round_wire: String = Exact.stringify(round_trip)
	var json_selected: Dictionary = Forest.arrangement_constructor(round_trip, definition)
	_expect(json_selected.error.is_empty() and json_selected.descriptor.schema_version == 1 and typeof(json_selected.descriptor.schema_version) == typeof(round_trip.arrangement.schema_version) and Exact.stringify(round_trip) == round_wire, "integral JSON schemas select without rewriting scalar representations")
	_expect(Forest.LOCAL_VERSION == 1 and Forest.WORLD_REVISION == 1, "outer local version and encounter world revision remain1")

	var bad: Dictionary = local.duplicate(true)
	bad.arrangement.profile = "standard"
	_refused(bad, definition, "descriptor profile cannot cross-join saved Scheduler profile")
	bad = local.duplicate(true); bad.scheduler.profile.reserved_threat_budget = 0
	_refused(bad, definition, "constructor cannot configure a forged saved profile")
	bad = local.duplicate(true); bad.scheduler.profile.raw_damage_multiplier = 1.0000000000000002
	_refused(bad, definition, "canonical saved profile scalar bits cannot drift by one bit")
	bad = local.duplicate(true); bad.arrangement.order[4] = bad.arrangement.order[0]
	_refused(bad, definition, "duplicate existing unit cannot replace a Root slot")
	bad = local.duplicate(true); bad.arrangement.order[4] = "foreign-root"
	_refused(bad, definition, "foreign source cannot acquire a native slot")
	bad = local.duplicate(true); bad.arrangement.order.pop_back()
	_refused(bad, definition, "partial roster cannot configure missing recipients")
	bad = local.duplicate(true); bad.arrangement.recipe_id = "A3-L2/unretained@v1"
	_refused(bad, definition, "unretained recipe cannot construct native bindings")
	bad = local.duplicate(true); bad.arrangement.schema_version = true
	_refused(bad, definition, "boolean is not an arrangement schema")
	bad = local.duplicate(true); bad.arrangement["authority"] = "native"
	_refused(bad, definition, "extra descriptor keys grant no source authority")
	bad = local.duplicate(true); bad.schema_version = 1
	_refused(bad, definition, "API2 cannot impersonate inner schema1")
	bad = _local("challenge"); bad.arrangement = challenge.duplicate(true)
	_refused(bad, definition, "API1 cannot smuggle a current recipe into legacy capture")
	bad = local.duplicate(true); bad.erase("arrangement")
	_refused(bad, definition, "API2 requires its closed arrangement receipt")
	bad = local.duplicate(true); bad.scheduler.profile.id = "unknown"
	_refused(bad, definition, "unknown saved profile is refused before construction")
	bad = local.duplicate(true); bad[7] = "foreign key"
	_refused(bad, definition, "non-string local key is refused")

	var tampered: Dictionary = definition.duplicate(true)
	var order: Array = tampered.recipes[2].order
	var first: String = order[0]; order[0] = order[1]; order[1] = first
	_expect(not Forest.arrangement_definition_error(tampered).is_empty(), "self-consistent retained legacy recipe permutation cannot repurpose its ID")
	tampered = definition.duplicate(true); tampered.unit_ids[0] = tampered.unit_ids[1]
	_expect(not Forest.arrangement_definition_error(tampered).is_empty(), "duplicate authored inventory definition is refused")
	tampered = definition.duplicate(true); tampered.current.standard = Forest.CHALLENGE_RECIPE
	_expect(not Forest.arrangement_definition_error(tampered).is_empty(), "current mapping cannot cross profile identities")

	# Mutating any returned tree must not alias the caller definition/descriptor.
	selected.descriptor.order[0] = "changed-return"
	selected.entries["l2-trunk-root"] = 99
	selected.starts["l2-trunk-root"] = Vector3(99, 99, 99)
	var independent: Dictionary = Forest.arrangement_constructor(local, definition)
	_expect(independent.error.is_empty() and independent.descriptor == challenge and independent.entries["l2-trunk-root"] == 3 and independent.starts["l2-trunk-root"] == Vector3(-1.3, 0, -4), "nested returned descriptor/layout changes do not affect another resolution")
	_expect(Exact.stringify(local) == before_local and Exact.stringify(challenge) == original_challenge and Exact.stringify(definition) == original_definition, "all pure calls leave caller-owned local/descriptor/definition exact")
	complete = true
	_finish()


func _local(profile: String, descriptor: Dictionary = {}) -> Dictionary:
	var resolver := Difficulty.new()
	var value: Dictionary = {"api_revision": Forest.LEGACY_ROUTE_API if descriptor.is_empty() else Forest.ROUTE_API, "schema_version": 1 if descriptor.is_empty() else 2, "scenery": {}, "scheduler": {"profile": resolver.profile(profile)}, "sources": {}, "route": {}}
	if not descriptor.is_empty(): value["arrangement"] = descriptor.duplicate(true)
	return value


func _refused(local: Dictionary, definition: Dictionary, label: String) -> void:
	var before: String = Exact.stringify(local)
	var original: Dictionary = local.duplicate(true)
	var result: Dictionary = Forest.arrangement_constructor(local, definition)
	_expect(not String(result.error).is_empty() and not result.has("starts") and local == original and before == Exact.stringify(local), label)


func _finish() -> void:
	var path: String = OS.get_environment("CINDER_FOREST_PURE_REPORT")
	if not path.is_empty():
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			_expect(false, "owned pure report opens")
		else:
			file.store_string(JSON.stringify({"schema_version": 1, "checks": checks, "failures": failures, "first_failure": first_failure, "rows": rows, "complete": complete, "success": complete and failures == 0}, "\t") + "\n")
			file.close()
			print("CINDER_FOREST_PURE_REPORT path=" + path + " sha256=" + FileAccess.get_sha256(path))
	print("Forest arrangement pure: %d checks/%d failures; complete=%s" % [checks, failures, str(complete)])
	quit(0 if complete and failures == 0 else 1)
