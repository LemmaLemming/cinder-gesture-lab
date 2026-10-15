extends SceneTree
## Pure metadata checks; execution is recorded separately from preparation.
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")

var checks: int = 0
var failures: int = 0
var complete: bool = false
var first_failure: Dictionary = {}
var records: Array[Dictionary] = []
var report_path: String = ""
var source_before: Dictionary = {}
const HELPER_URI: String = "res://scripts/combat/encounter_arrangement.gd"
const TEST_URI: String = "res://tests/encounter_arrangement_smoke.gd"


func _initialize() -> void:
	report_path = OS.get_environment("CINDER_ENCOUNTER_ARRANGEMENT_REPORT")
	if report_path.is_empty():
		report_path = ProjectSettings.globalize_path("res://.cinder/encounter-arrangement-smoke-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	source_before = _source_observations()
	_run.call_deferred()


func _run() -> void:
	var authored: Dictionary = _authored()
	var untouched: String = Exact.stringify(authored)
	var old = Arrangement.new(authored)
	var saved: Dictionary = old.select_fresh("challenge")
	if not _expect(old.last_error.is_empty() and saved.get("recipe_id") == "far-first@v1" and saved.get("order") == ["far", "paired", "near"], "fresh Challenge resolves only its authored complete permutation"):
		_finish(); return
	_expect(old.select_fresh("assisted").get("order") == ["near", "paired", "far"] and old.select_fresh("standard").get("order") == ["paired", "near", "far"], "the three fresh profiles select authored existing-unit orders without altering units")
	_expect(Exact.stringify(authored) == untouched, "constructor and fresh selections never mutate caller definitions")
	var saved_wire: String = Exact.stringify(saved)

	# Changed preference is merely another fresh selection; restore has no such
	# parameter. Retained old recipe survives a later current mapping/version.
	var next_definition: Dictionary = _authored()
	next_definition.recipes.append({"recipe_id": "paired-first@v2", "profile": "challenge", "order": ["paired", "far", "near"]})
	next_definition.current.challenge = "paired-first@v2"
	var next = Arrangement.new(next_definition)
	var fresh: Dictionary = next.select_fresh("challenge")
	next.select_fresh("assisted")
	var restored: Dictionary = next.restore(saved)
	_expect(fresh.get("recipe_id") == "paired-first@v2" and fresh.get("order") == ["paired", "far", "near"] and Exact.stringify(restored) == saved_wire, "new mapping/preference affects fresh selection while restore preserves the exact historical recipe/order")
	_expect(Exact.stringify(saved) == saved_wire, "restoration leaves caller saved descriptor byte-exact")

	var tampered: Dictionary = next_definition.duplicate(true)
	tampered.recipes[2].order = ["near", "far", "paired"]
	var tampered_helper = Arrangement.new(tampered)
	_expect(tampered_helper.last_error.is_empty() and tampered_helper.restore(saved).is_empty() and not tampered_helper.last_error.is_empty(), "same historical recipe ID with tampered complete order rejects its original descriptor")
	var removed: Dictionary = next_definition.duplicate(true)
	removed.recipes.remove_at(2)
	var missing_helper = Arrangement.new(removed)
	_expect(missing_helper.last_error.is_empty() and missing_helper.restore(saved).is_empty() and not missing_helper.last_error.is_empty(), "missing retained historical recipe refuses instead of substituting the current recipe")

	var json_value: Variant = JSON.parse_string(JSON.stringify(saved))
	var json_restored: Dictionary = next.restore(json_value)
	_expect(not json_restored.is_empty() and Codec.is_integer(json_restored.schema_version, 1, 1) and json_restored.profile == saved.profile and json_restored.recipe_id == saved.recipe_id and json_restored.order == saved.order, "ordinary JSON integral schema roundtrip preserves owned recipe/profile/order")
	_expect(Exact.stringify(json_restored) == Exact.stringify(json_value), "restore preserves the caller's accepted integral schema representation without coercion")

	# All live object storage is detached from constructor and output aliases.
	authored.unit_ids[0] = "foreign"
	authored.recipes[2].order.reverse()
	authored.current.challenge = "missing@v1"
	var exposed: Dictionary = old.definition()
	exposed.recipes[2].order.clear()
	exposed.unit_ids.clear()
	var output: Dictionary = old.select_fresh("challenge")
	output.get("order", []).clear(); output.profile = "assisted"
	var restored_output: Dictionary = next.restore(saved)
	restored_output.get("order", []).reverse()
	_expect(Exact.stringify(old.select_fresh("challenge")) == saved_wire and Exact.stringify(next.restore(saved)) == saved_wire and Exact.stringify(saved) == saved_wire, "constructor input, definition output, selection output and restored output mutations cannot alias retained authority or caller saves")

	_negative_cases(next, saved)
	_expect(Exact.stringify(next_definition) == Exact.stringify(_next_authored()) and Exact.stringify(saved) == saved_wire, "failed/successful validation and restore never mutate supplied definitions or saved descriptor")
	complete = true
	_finish()


func _negative_cases(helper: CinderEncounterArrangement, saved: Dictionary) -> void:
	# These rejection cases guard meaningful caller/persistence failures rather
	# than reproduce every implementation branch or broaden into a large matrix.
	var bad_definitions: Array[Dictionary] = []
	var bad: Dictionary = _authored()
	bad.unit_ids = ["near", "near", "far"]
	bad_definitions.append({"label": "duplicate existing unit definitions", "definition": bad})
	bad = _authored(); bad.recipes[0].order = ["near", "near", "far"]
	bad_definitions.append({"label": "duplicate permutation unit", "definition": bad})
	bad = _authored(); bad.recipes[0].order = ["near", "paired", "foreign"]
	bad_definitions.append({"label": "foreign permutation unit", "definition": bad})
	bad = _authored(); bad.recipes[0].order = ["near", "far"]
	bad_definitions.append({"label": "missing permutation unit", "definition": bad})
	bad = _authored(); bad.recipes.append(bad.recipes[0].duplicate(true))
	bad_definitions.append({"label": "duplicate immutable recipe ID", "definition": bad})
	bad = _authored(); bad.recipes[0].recipe_id = "unversioned"
	bad_definitions.append({"label": "unversioned recipe identity", "definition": bad})
	bad = _authored(); bad.current.challenge = "missing@v1"
	bad_definitions.append({"label": "unknown current recipe", "definition": bad})
	bad = _authored(); bad.current.assisted = "far-first@v1"
	bad_definitions.append({"label": "cross-profile current mapping", "definition": bad})
	bad = _authored(); bad.current.erase("standard")
	bad_definitions.append({"label": "missing profile mapping", "definition": bad})
	bad = _authored(); bad["damage_multiplier"] = 2.0
	bad_definitions.append({"label": "unsupported definition authority field", "definition": bad})
	bad = _authored(); bad.recipes[0].order = PackedStringArray(["near", "paired", "far"])
	bad_definitions.append({"label": "non-JSON packed order type", "definition": bad})
	for row: Dictionary in bad_definitions:
		var invalid = Arrangement.new(row.definition)
		_expect(not invalid.last_error.is_empty() and invalid.select_fresh("standard").is_empty() and not invalid.last_error.is_empty(), "invalid definition refuses fresh selection: " + row.label)

	var malformed: Array[Dictionary] = []
	bad = saved.duplicate(true); bad.recipe_id = "missing@v1"
	malformed.append({"label": "unknown saved recipe", "descriptor": bad})
	bad = saved.duplicate(true); bad.profile = "standard"
	malformed.append({"label": "saved profile differs from retained recipe", "descriptor": bad})
	bad = saved.duplicate(true); bad.profile = "nightmare"
	malformed.append({"label": "unknown saved profile", "descriptor": bad})
	bad = saved.duplicate(true); bad.order = ["near", "near", "far"]
	malformed.append({"label": "duplicate saved unit", "descriptor": bad})
	bad = saved.duplicate(true); bad.order = ["near", "paired", "foreign"]
	malformed.append({"label": "foreign saved unit", "descriptor": bad})
	bad = saved.duplicate(true); bad.order = ["near", "far"]
	malformed.append({"label": "missing saved unit", "descriptor": bad})
	bad = saved.duplicate(true); bad.order = ["paired", "far", "near"]
	malformed.append({"label": "other complete permutation under old recipe ID", "descriptor": bad})
	bad = saved.duplicate(true); bad.order = "far,paired,near"
	malformed.append({"label": "malformed saved order type", "descriptor": bad})
	bad = saved.duplicate(true); bad.erase("recipe_id")
	malformed.append({"label": "missing descriptor field", "descriptor": bad})
	bad = saved.duplicate(true); bad["priority"] = 4
	malformed.append({"label": "unsupported descriptor authority field", "descriptor": bad})
	for schema: Variant in [true, "1", 1.5, 2]:
		bad = saved.duplicate(true); bad.schema_version = schema
		malformed.append({"label": "malformed or unsupported saved schema " + str(schema), "descriptor": bad})
	for row: Dictionary in malformed:
		var before: String = Exact.stringify(row.descriptor)
		_expect(helper.restore(row.descriptor).is_empty() and not helper.last_error.is_empty() and Exact.stringify(row.descriptor) == before, "invalid saved descriptor refuses without mutation: " + row.label)
	_expect(helper.select_fresh("nightmare").is_empty() and not helper.last_error.is_empty(), "unknown fresh profile never falls back to another arrangement")


func _authored() -> Dictionary:
	return {
		"schema_version": 1,
		"unit_ids": ["near", "paired", "far"],
		"recipes": [
			{"recipe_id": "near-first@v1", "profile": "assisted", "order": ["near", "paired", "far"]},
			{"recipe_id": "paired-first@v1", "profile": "standard", "order": ["paired", "near", "far"]},
			{"recipe_id": "far-first@v1", "profile": "challenge", "order": ["far", "paired", "near"]}
		],
		"current": {"assisted": "near-first@v1", "standard": "paired-first@v1", "challenge": "far-first@v1"}
	}


func _next_authored() -> Dictionary:
	var result: Dictionary = _authored()
	result.recipes.append({"recipe_id": "paired-first@v2", "profile": "challenge", "order": ["paired", "far", "near"]})
	result.current.challenge = "paired-first@v2"
	return result


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	var row: Dictionary = {"check": checks, "ok": ok, "label": label}
	records.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
		print("FAIL encounter arrangement: " + label)
	return ok


func _source_observations() -> Dictionary:
	return {HELPER_URI: FileAccess.get_sha256(HELPER_URI), TEST_URI: FileAccess.get_sha256(TEST_URI)}


func _finish() -> void:
	var payload: Dictionary = {"schema_version": 1, "checks": checks, "failures": failures, "complete": complete, "success": complete and failures == 0, "first_failure": first_failure, "rows": records, "source_observations_before": source_before, "source_observations_after": _source_observations(), "scope": "pure owner-authored versioned existing-unit permutation metadata, retained historical restore and defensive copies only; no native runtime consumer, player-decision validation or accepted Challenge coverage"}
	# Only bounded ordinary counters/booleans/strings/rows/source hashes here;
	# no snapshot floats, tagged native values or gameplay state is converted.
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		_expect(false, "structured report is writable")
	else:
		file.store_string(JSON.stringify(payload, "\t") + "\n"); file.close()
		print("CINDER_ENCOUNTER_ARRANGEMENT_REPORT path=" + report_path + " sha256=" + FileAccess.get_sha256(report_path))
	print("Encounter arrangement smoke: %d checks/%d failures; complete=%s; pure metadata only" % [checks, failures, str(complete)])
	quit(0 if complete and failures == 0 else 1)
