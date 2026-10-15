extends SceneTree
## Focused immutable construction metadata checks against promoted Root sources and literal legacy inputs.
## Edited new18/clear copies below are construction metadata ONLY; never a
## valid native packet, earned clear, or substitute for full paired preflight.
const Parent = preload("res://scripts/acts/act2/weybridge.gd")
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const DATA: String = "res://data/campaign/act2/a2_l2_difficulty_arrangements.json"
const FIXTURES: String = "res://tests/acts/act2/fixtures/a2_l2_difficulty_legacy/"
var rows: Array[Dictionary] = []
var failures: int = 0
var first_failure: Dictionary = {}
var complete: bool = false
var report_path: String

func _initialize() -> void:
	report_path = OS.get_environment("CINDER_A2_L2_ARRANGEMENT_PURE_REPORT")
	_run.call_deferred()

func _run() -> void:
	var definition: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not _expect(not report_path.is_empty() and OS.get_cmdline_user_args().is_empty() and Parent.arrangement_definition_error(definition).is_empty(), "actual authored definition and explicit report output open"):
		_finish(); return
	var before: String = Exact.stringify(definition)
	var selector := Arrangement.new(definition)
	var standard: Dictionary = selector.select_fresh("standard")
	var challenge: Dictionary = selector.select_fresh("challenge")
	var normal: Dictionary = Parent.arrangement_layout(standard, definition)
	var changed: Dictionary = Parent.arrangement_layout(challenge, definition)
	if not _expect(normal.error.is_empty() and changed.error.is_empty(), "both actual retained fresh recipes resolve"):
		_finish(); return
	_expect(normal.positions == Parent.CrossingSequence.ACTORS, "Standard keeps every exact original native root")
	_expect(changed.positions.shelter_handler == Parent.CrossingSequence.ACTORS.shelter_scout and changed.positions.shelter_scout == Parent.CrossingSequence.ACTORS.shelter_handler, "Challenge exchanges near Handler/rear Scout ground slots")
	var other_four: bool = true
	for id: String in ["village_scout", "yard_handler", "apron_handler", "crossing_scout"]:
		other_four = other_four and changed.positions[id] == Parent.CrossingSequence.ACTORS[id]
	_expect(other_four and changed.positions.size() == 6, "other four original recipients and native heights stay exact")
	var remapped: Dictionary = definition.duplicate(true)
	remapped.current.challenge = Parent.L2_CANONICAL_RECIPES.challenge
	var remap_selector := Arrangement.new(remapped)
	var later_fresh: Dictionary = Parent.arrangement_layout(remap_selector.select_fresh("challenge"), remapped)
	var retained: Dictionary = Parent.arrangement_layout(challenge, remapped)
	_expect(later_fresh.error.is_empty() and later_fresh.positions == normal.positions and retained.error.is_empty() and retained.positions == changed.positions, "changed current mapping changes only fresh selection; retained prior recipe remains physical")
	var json_descriptor: Variant = JSON.parse_string(JSON.stringify(challenge))
	var json_selected: Dictionary = Parent.arrangement_layout(json_descriptor, definition)
	_expect(json_selected.error.is_empty() and Exact.stringify(json_selected.descriptor) == Exact.stringify(json_descriptor) and json_selected.positions == changed.positions, "integral JSON descriptor schema survives without caller/tag normalization")
	for profile: String in ["standard", "challenge"]:
		var wire: String = FileAccess.get_file_as_string(FIXTURES + profile + "-entrance.exact.json")
		var parsed: Dictionary = Exact.parse(wire)
		if not _expect(parsed.get("accepted") == true, "actual original literal is available for pure receipt dispatch: " + profile):
			_finish(); return
		var original: Dictionary = parsed.value.level.local
		var original_bits: String = Exact.stringify(original)
		var old: Dictionary = Parent.arrangement_constructor(original, remapped)
		_expect(old.error.is_empty() and old.legacy == true and old.profile_id == profile and old.positions == normal.positions, "old15 literal keeps original saved-profile positions independently of today's mapping: " + profile)
		var fresh_descriptor: Dictionary = selector.select_fresh(profile)
		var metadata: Dictionary = original.duplicate(true)
		metadata["api_revision"] = Parent.L2_ARRANGEMENT_API
		metadata["schema_version"] = 2
		metadata["arrangement"] = fresh_descriptor
		var current: Dictionary = Parent.arrangement_constructor(metadata, definition)
		_expect(current.error.is_empty() and current.legacy == false and current.positions == (changed.positions if profile == "challenge" else normal.positions), "closed18 construction receipt selects trusted positions; not full native acceptance: " + profile)
		var bad: Dictionary = metadata.duplicate(true)
		bad.erase("schema_version")
		_expect(not Parent.arrangement_constructor(bad, definition).error.is_empty(), "partial mixed15/18 envelope refuses")
		bad = metadata.duplicate(true); bad["foreign"] = true
		_expect(not Parent.arrangement_constructor(bad, definition).error.is_empty(), "extra construction key refuses")
		bad = metadata.duplicate(true); bad.profile_id = "assisted"
		_expect(not Parent.arrangement_constructor(bad, definition).error.is_empty(), "saved local profile cannot disagree with the live canonical Scheduler")
		bad = metadata.duplicate(true); bad.scheduler.profile.raw_damage_multiplier += 0.000000000001
		_expect(not Parent.arrangement_constructor(bad, definition).error.is_empty(), "one-bit-scale canonical profile change refuses before construction")
		# Synthetic clear metadata exercises only the constructor branch. Actors,
		# HP and native consumer history remain unvalidated and are never applied.
		var clear_metadata: Dictionary = metadata.duplicate(true)
		var sequence = Parent.CrossingSequence.new()
		sequence.stage_index = 11
		sequence.defeated_ids.assign(Parent.L2_SOURCE_IDS)
		sequence.completed_feet.assign(["foot_demo", "foot_apron", "foot_left", "foot_right"])
		sequence.crossed_contacts.assign(["yard_exit", "before_crossing", "far_apron", "before_shelter"])
		clear_metadata.sequence = sequence.snapshot_state()
		clear_metadata.scheduler.profile = {}
		clear_metadata.scheduler.encounter_id = ""
		clear_metadata.scheduler.reservations = []
		var clear: Dictionary = Parent.arrangement_constructor(clear_metadata, definition)
		_expect(clear.error.is_empty() and clear.profile_id == profile, "pure clear receipt uses saved local profile with original empty Scheduler; no native clear claim")
		bad = clear_metadata.duplicate(true); bad.scheduler.profile = metadata.scheduler.profile.duplicate(true)
		_expect(not Parent.arrangement_constructor(bad, definition).error.is_empty(), "clear receipt cannot retain a live Scheduler epoch/profile")
		_expect(Exact.stringify(original) == original_bits, "literal old local input remains bit/tag exact after pure calls")
	var bad_descriptor: Dictionary = challenge.duplicate(true)
	bad_descriptor.order[0] = bad_descriptor.order[1]
	_expect(not Parent.arrangement_layout(bad_descriptor, definition).error.is_empty(), "duplicate/missing existing unit refuses")
	bad_descriptor = challenge.duplicate(true); bad_descriptor.order[0] = "foreign-unit"
	_expect(not Parent.arrangement_layout(bad_descriptor, definition).error.is_empty(), "foreign unit refuses")
	var bad_definition: Dictionary = definition.duplicate(true)
	bad_definition.recipes[3].order = Parent.L2_SOURCE_IDS.duplicate()
	_expect(not Parent.arrangement_definition_error(bad_definition).is_empty(), "retained recipe ID cannot be repurposed with canonical contents")
	bad_definition = definition.duplicate(true); bad_definition.current.standard = Parent.L2_CHALLENGE_RECIPE
	_expect(not Parent.arrangement_definition_error(bad_definition).is_empty(), "current mapping cannot cross profile ownership")
	var isolated: Dictionary = Parent.arrangement_layout(challenge, definition)
	isolated.positions.shelter_handler = Vector3(90, 90, 90)
	isolated.descriptor.order[0] = "foreign-unit"
	_expect(Parent.arrangement_layout(challenge, definition).positions == changed.positions and Exact.stringify(definition) == before, "returned tree mutation cannot alias trusted positions, descriptor or caller definition")
	complete = true
	_finish()

func _expect(ok: bool, label: String) -> bool:
	var row: Dictionary = {"check": rows.size() + 1, "ok": ok, "label": label}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
	return ok

func _finish() -> void:
	var report: Dictionary = {"schema_version": 1, "checks": rows.size(), "failures": failures, "rows": rows, "first_failure": first_failure, "complete": complete, "success": complete and failures == 0, "scope": "Pure immutable construction/receipt metadata only; literal old inputs plus disclosed synthetic new18/clear metadata. No native packet acceptance, gameplay, campaign clear or performance credit."}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: print("Weybridge pure report destination failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("CINDER_A2_L2_ARRANGEMENT_PURE_REPORT path=" + report_path + " sha256=" + FileAccess.get_sha256(report_path))
	print("Weybridge arrangement pure: %d checks/%d failures; complete=%s" % [rows.size(), failures, str(complete)])
	quit(0 if complete and failures == 0 else 1)
