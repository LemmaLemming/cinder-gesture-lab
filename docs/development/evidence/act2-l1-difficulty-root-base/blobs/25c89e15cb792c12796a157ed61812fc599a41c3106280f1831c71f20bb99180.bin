extends SceneTree
## Pure metadata and nonnative delegation controls.
## Synthetic current20/all-profile/child-envelope copies are not native packets.
## Four genuine old17 inputs remain unchanged. No fake completed state/history.
const Parent = preload("res://scripts/acts/act2/horsell_common.gd")
const Child2 = preload("res://scripts/acts/act2/weybridge.gd")
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const DATA: String = "res://data/campaign/act2/a2_l1_difficulty_arrangements.json"
const L2_DATA: String = "res://data/campaign/act2/a2_l2_difficulty_arrangements.json"
const FIXTURES: String = "res://tests/acts/act2/fixtures/a2_l1_difficulty_legacy/"
const PRODUCER_SHA: String = "e20f7fde09c3d5c3fb5e151d060cf440c8d33d0bd36032a5280f5603820cbad4"

class L2Probe:
	extends "res://scripts/acts/act2/weybridge.gd"
	var test_entry_calls: int = 0
	func _on_enter_level() -> void: test_entry_calls += 1

class L3Probe:
	extends "res://scripts/acts/act2/ruined_house.gd"
	var test_entry_calls: int = 0
	func _on_enter_level() -> void: test_entry_calls += 1

class L4Probe:
	extends "res://scripts/acts/act2/london_approaches.gd"
	var test_entry_calls: int = 0
	func _on_enter_level() -> void: test_entry_calls += 1

var rows: Array[Dictionary] = []
var failures: int = 0
var first_failure: Dictionary = {}
var complete: bool = false
var finishing: bool = false
var report_path: String = ""
var source_before: Dictionary = {}

func _initialize() -> void:
	report_path = OS.get_environment("CINDER_A2_L1_ARRANGEMENT_PURE_REPORT")
	source_before = _sources()
	_run.call_deferred()

func _run() -> void:
	var definition: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not _expect(not report_path.is_empty() and report_path.is_absolute_path() and OS.get_cmdline_user_args().is_empty() and Parent._l1_arrangement_definition_error(definition).is_empty(), "explicit output and actual finite retained Horsell definition"):
		_finish(); return
	if not _expect(FileAccess.get_sha256(FIXTURES + "producer-native-report.json") == PRODUCER_SHA, "genuine original producer report identity"):
		_finish(); return
	var definition_bits: String = Exact.stringify(definition)
	var selector = Arrangement.new(definition)
	var canonical: Dictionary = Parent.Sequence.ACTOR_POSITIONS
	var challenge: Dictionary = selector.select_fresh("challenge")
	var changed: Dictionary = Parent._l1_arrangement_layout(challenge, definition)
	if not _expect(changed.error.is_empty(), "actual retained fresh Challenge metadata resolves"):
		_finish(); return
	for profile: String in ["assisted", "standard"]:
		var current: Dictionary = Parent._l1_arrangement_layout(selector.select_fresh(profile), definition)
		_expect(current.error.is_empty() and current.positions == canonical, "all seven original roots unchanged for " + profile)
	var only_common_x: bool = changed.positions.size() == 7 and changed.positions.common_left == canonical.common_right and changed.positions.common_right == canonical.common_left
	for id: String in Parent.L1_SOURCE_IDS:
		only_common_x = only_common_x and changed.positions[id].y == canonical[id].y and changed.positions[id].z == canonical[id].z
		if id not in ["common_left", "common_right"]: only_common_x = only_common_x and changed.positions[id] == canonical[id]
	_expect(only_common_x, "Challenge exchanges only common X slots; all other roots/Y/Z exact")
	var remapped: Dictionary = definition.duplicate(true)
	remapped.current.challenge = Parent.L1_CANONICAL_RECIPES.challenge
	var remap_selector = Arrangement.new(remapped)
	var later: Dictionary = Parent._l1_arrangement_layout(remap_selector.select_fresh("challenge"), remapped)
	var retained: Dictionary = Parent._l1_arrangement_layout(challenge, remapped)
	_expect(later.error.is_empty() and later.positions == canonical and retained.error.is_empty() and retained.positions == changed.positions, "new current mapping cannot rewrite retained Challenge construction")
	var json_descriptor: Variant = JSON.parse_string(JSON.stringify(challenge))
	var from_json: Dictionary = Parent._l1_arrangement_layout(json_descriptor, definition)
	_expect(from_json.error.is_empty() and from_json.positions == changed.positions and Exact.stringify(from_json.descriptor) == Exact.stringify(json_descriptor), "integral JSON schema accepted without rewriting caller scalar tags")
	for saved_profile: String in ["standard", "challenge"]:
		for stage: String in ["entrance", "arrival-warning"]:
			var path: String = FIXTURES + saved_profile + "-" + stage + ".exact.json"
			var wire: String = FileAccess.get_file_as_string(path)
			var parsed: Dictionary = Exact.parse(wire)
			if not _expect(parsed.get("accepted") == true and parsed.get("value") is Dictionary, "actual old17 literal available: " + saved_profile + "/" + stage):
				_finish(); return
			var original: Dictionary = parsed.value.level.local
			var bits: String = Exact.stringify(original)
			if saved_profile == "standard" and stage == "entrance":
				# Positive compatibility-only copies: original native profile
				# accepts equal int/float values. Do not rewrite genuine wires.
				var int_budget: Dictionary = original.duplicate(true)
				int_budget.scheduler.profile.reserved_threat_budget = 2
				var float_budget: Dictionary = original.duplicate(true)
				float_budget.scheduler.profile.reserved_threat_budget = 2.0
				var int_bits: String = Exact.stringify(int_budget)
				var float_bits: String = Exact.stringify(float_budget)
				var old_int: Dictionary = Parent._l1_arrangement_constructor(int_budget, definition)
				var old_float: Dictionary = Parent._l1_arrangement_constructor(float_budget, definition)
				_expect(int_budget.scheduler.profile.reserved_threat_budget is int and float_budget.scheduler.profile.reserved_threat_budget is float and int_bits != float_bits and Codec.same_values(int_budget.scheduler.profile, float_budget.scheduler.profile) and old_int.error.is_empty() and old_float.error.is_empty() and old_int.legacy and old_float.legacy and old_int.positions == canonical and old_float.positions == canonical, "old17 constructor preserves original Scheduler equal int2/float2.0 profile compatibility; no tag normalization")
				_expect(Exact.stringify(int_budget) == int_bits and Exact.stringify(float_budget) == float_bits and Exact.stringify(parsed.value) == wire, "numeric compatibility copies and genuine original wire remain independently bit/tag exact")
			var old: Dictionary = Parent._l1_arrangement_constructor(original, remapped)
			_expect(original.size() == 17 and old.error.is_empty() and old.legacy and old.profile_id == saved_profile and old.positions == canonical, "old17 canonical positions follow saved profile regardless current mapping")
			# These isolated metadata copies intentionally retain old native
			# components. They are constructor inputs ONLY, never restored.
			for requested: String in ["assisted", "standard", "challenge"]:
				var metadata: Dictionary = original.duplicate(true)
				metadata.profile_id = requested
				metadata.scheduler.profile = Difficulty.new().profile(requested)
				metadata["api_revision"] = Parent.L1_ARRANGEMENT_API
				metadata["schema_version"] = 2
				metadata["arrangement"] = selector.select_fresh(requested)
				var metadata_bits: String = Exact.stringify(metadata)
				var selected: Dictionary = Parent._l1_arrangement_constructor(metadata, definition)
				_expect(metadata.size() == 20 and selected.error.is_empty() and not selected.legacy and selected.profile_id == requested and selected.positions == (changed.positions if requested == "challenge" else canonical), "new20/all-profile constructor metadata only: " + requested)
				_expect(Exact.stringify(metadata) == metadata_bits, "pure constructor never mutates synthetic caller input")
			var new20: Dictionary = original.duplicate(true)
			new20["api_revision"] = Parent.L1_ARRANGEMENT_API
			new20["schema_version"] = 2
			new20["arrangement"] = selector.select_fresh(saved_profile)
			for key: String in ["api_revision", "schema_version", "arrangement"]:
				var partial: Dictionary = new20.duplicate(true); partial.erase(key)
				_expect(not Parent._l1_arrangement_constructor(partial, definition).error.is_empty(), "mixed17/20 partial envelope refuses: " + key)
			var bad: Dictionary = new20.duplicate(true); bad["extra"] = true
			_expect(not Parent._l1_arrangement_constructor(bad, definition).error.is_empty(), "unknown local key refuses")
			bad = new20.duplicate(true); bad.schema_version = "2"
			_expect(not Parent._l1_arrangement_constructor(bad, definition).error.is_empty(), "malformed inner schema type refuses")
			bad = new20.duplicate(true); bad.profile_id = "assisted"
			_expect(not Parent._l1_arrangement_constructor(bad, definition).error.is_empty(), "local/Scheduler profile mismatch refuses")
			bad = new20.duplicate(true); bad.scheduler.profile.raw_damage_multiplier += 0.01
			_expect(not Parent._l1_arrangement_constructor(bad, definition).error.is_empty(), "material outside-tolerance canonical saved profile tamper refuses")
			bad = new20.duplicate(true); bad.scheduler.encounter_id = "foreign-epoch"
			_expect(not Parent._l1_arrangement_constructor(bad, definition).error.is_empty(), "foreign saved epoch refuses")
			_expect(Exact.stringify(original) == bits and Exact.stringify(parsed.value) == wire, "whole genuine old wire remains exact after pure/refusal calls")
	var bad_descriptor: Dictionary = challenge.duplicate(true); bad_descriptor.order[0] = bad_descriptor.order[1]
	_expect(not Parent._l1_arrangement_layout(bad_descriptor, definition).error.is_empty(), "duplicate/missing existing source refuses")
	bad_descriptor = challenge.duplicate(true); bad_descriptor.order[0] = "foreign-source"
	_expect(not Parent._l1_arrangement_layout(bad_descriptor, definition).error.is_empty(), "foreign source refuses")
	bad_descriptor = challenge.duplicate(true); bad_descriptor.recipe_id = "A2-L1/unknown@v1"
	_expect(not Parent._l1_arrangement_layout(bad_descriptor, definition).error.is_empty(), "unknown retained recipe refuses")
	bad_descriptor = challenge.duplicate(true); bad_descriptor.profile = "standard"
	_expect(not Parent._l1_arrangement_layout(bad_descriptor, definition).error.is_empty(), "recipe profile mismatch refuses")
	var bad_definition: Dictionary = definition.duplicate(true); bad_definition.recipes[3].order = Parent.L1_SOURCE_IDS.duplicate()
	_expect(not Parent._l1_arrangement_definition_error(bad_definition).is_empty(), "retained recipe content cannot be repurposed")
	var isolated: Dictionary = Parent._l1_arrangement_layout(challenge, definition)
	isolated.positions.common_left = Vector3(90, 90, 90); isolated.descriptor.order[0] = "foreign"
	_expect(Parent._l1_arrangement_layout(challenge, definition).positions == changed.positions and Exact.stringify(definition) == definition_bits, "nested returned tree cannot alias trusted data or caller definition")
	var mutable: Dictionary = definition.duplicate(true)
	var protected_selector = Arrangement.new(mutable)
	mutable.recipes[3].order = Parent.L1_SOURCE_IDS.duplicate()
	_expect(protected_selector.select_fresh("challenge") == challenge, "selector copies caller definition rather than retaining an alias")
	_child_controls()
	complete = true
	_finish()

func _child_controls() -> void:
	# Pure envelope shape and out-of-tree dynamic hook probes only. These are
	# not child saved packets, live sources or native construction credit.
	var old_l2: Dictionary = {}
	for key: String in Child2.CROSSING_LOCAL_KEYS: old_l2[key] = null
	var new_l2: Dictionary = old_l2.duplicate(true)
	new_l2["api_revision"] = Child2.L2_ARRANGEMENT_API
	new_l2["schema_version"] = 2
	new_l2["arrangement"] = {}
	_expect(old_l2.size() == 15 and new_l2.size() == 18 and Child2._l2_local_envelope_error(old_l2).is_empty() and Child2._l2_local_envelope_error(new_l2).is_empty(), "L2 retains its own closed15/18 envelope grammar, not Horsell17/20")
	var sentinel: Dictionary = {"TEST_child_shape": ["preserve", 15, 18, 3]}
	var sentinel_bits: String = Exact.stringify(sentinel)
	var l2 = L2Probe.new(); l2.level_id = "A2-L2"
	var own_error: String = l2.call("_on_enter_restore_candidate", sentinel, {})
	_expect(l2.restore_candidate_construction_required() and own_error == Child2._l2_local_envelope_error(sentinel) and l2.test_entry_calls == 0 and l2.get("_l1_construction_started") == false, "actual L2 hook owns its refusal and never invokes L1 construction")
	l2.free()
	for selected: Array in [["A2-L3", L3Probe.new()], ["A2-L4", L4Probe.new()]]:
		var probe: Node = selected[1]; probe.set("level_id", selected[0])
		var error: String = probe.call("_on_enter_restore_candidate", sentinel, {})
		_expect(not probe.call("restore_candidate_construction_required") and error.is_empty() and probe.get("test_entry_calls") == 1 and probe.get("_l1_construction_started") == false and (probe.get("_l1_arrangement_descriptor") as Dictionary).is_empty(), "nonL1 inherited restore delegates to actual dynamic child entry without L1 metadata: " + String(selected[0]))
		probe.free()
	_expect(Exact.stringify(sentinel) == sentinel_bits, "nonL1 delegation does not reinterpret or mutate child sentinel")
	var preview = Parent.new(); preview.level_id = "A2-L1"; preview.art_preview_only = true
	_expect(not preview.restore_candidate_construction_required(), "art-preview remains outside new real-L1 construction opt-in")
	preview.free()

func _sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [get_script().resource_path, DATA, L2_DATA, FIXTURES + "PROVENANCE.json", FIXTURES + "producer-native-report.json", "res://scripts/acts/act2/horsell_common.gd", "res://scripts/acts/act2/horsell_sequence.gd", "res://scripts/acts/act2/weybridge.gd", "res://scripts/acts/act2/ruined_house.gd", "res://scripts/acts/act2/london_approaches.gd", "res://scripts/combat/encounter_arrangement.gd", "res://scripts/combat/difficulty.gd", "res://data/design/difficulty_profiles.json", "res://scripts/campaign/exact_json.gd", "res://scripts/campaign/snapshot_codec.gd"]:
		result[path] = FileAccess.get_sha256(path)
	for profile: String in ["standard", "challenge"]:
		for stage: String in ["entrance", "arrival-warning"]:
			var path: String = FIXTURES + profile + "-" + stage + ".exact.json"
			result[path] = FileAccess.get_sha256(path)
	return result

func _expect(ok: bool, label: String) -> bool:
	var row: Dictionary = {"check": rows.size() + 1, "ok": ok, "label": label}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
	return ok

func _finish() -> void:
	if finishing: return
	finishing = true
	var after: Dictionary = _sources()
	_expect(after == source_before, "all explicit pure sources/literal inputs remain unchanged")
	var report: Dictionary = {"schema_version": 1, "kind": "a2-l1-arrangement-pure", "checks": rows.size(), "failures": failures, "rows": rows, "first_failure": first_failure, "complete": complete, "success": complete and failures == 0, "source_before": source_before, "source_after": after, "scope": "Pure retained construction/closed17-20/all-profile/refusal/copy metadata and L2shape/L3L4nonnative dynamic delegation controls only. Four authentic old units untouched; synthetic metadata copies are not valid native packets, earned history/clear or campaign prefixes. No gameplay/Shell/visual/performance credit."}
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: print("Horsell pure report destination failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("CINDER_A2_L1_ARRANGEMENT_PURE_REPORT path=" + report_path + " sha256=" + FileAccess.get_sha256(report_path))
	print("Horsell arrangement pure: %d checks/%d failures; complete=%s" % [rows.size(), failures, str(complete)])
	quit(0 if complete and failures == 0 else 1)
