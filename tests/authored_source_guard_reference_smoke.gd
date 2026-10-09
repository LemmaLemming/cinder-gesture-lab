extends "res://tests/authored_enemy_sequence_smoke.gd"
## Targeted pure differential against the original public bounded comparator.
## The reference must pass full validation; hostile candidates are never copied
## or serialized. Native descriptors provide one real program, not gameplay.


func _run() -> void:
	var arena: Dictionary = await _arena()
	var sequence = Authored.new()
	var accepted: bool = sequence.configure(SEQUENCE_ID, _definition(arena.source.global_position), SOURCE_ID, EPOCH, GENERATION, "standard", _world_guards(arena))
	_expect(accepted, "reference program uses actual native collision/floor descriptors: " + sequence.last_error)
	if accepted:
		_reference_controls(sequence.snapshot_state())
	await _dispose(arena)
	print("Authored source guard reference smoke: %d checks, %d failures; pure exact differential only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


static func _next_double(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)


func _reference_controls(program: Dictionary) -> void:
	_reference_case("actual fully validated program copy", program, program.duplicate(true), true)
	var changed: Dictionary = program.duplicate(true)
	changed.timeline.slots[0].events[0].record.damage = _next_double(float(changed.timeline.slots[0].events[0].record.damage))
	_reference_case("actual program one binary64 bit", program, changed, false)
	var zero: float = PackedByteArray([0, 0, 0, 0, 0, 0, 0, 128]).decode_double(0)
	var subnormal: float = PackedByteArray([1, 0, 0, 0, 0, 0, 0, 0]).decode_double(0)
	_reference_case("signed zero differs", 0.0, zero, false)
	_reference_case("signed zero retained", zero, zero, true)
	_reference_case("subnormal differs from zero", 0.0, subnormal, false)
	_reference_case("subnormal retained", subnormal, subnormal, true)
	_reference_case("integer versus float", 1, 1.0, false)
	_reference_case("unsafe integer candidate", 1, 9007199254740992, false)
	_reference_case("safe integer endpoints", [-9007199254740991, 9007199254740991], [-9007199254740991, 9007199254740991], true)
	_reference_case("bool versus integer", false, 0, false)
	_reference_case("nil versus dictionary", null, {}, false)
	_reference_case("StringName value", "word", StringName("word"), false)
	_reference_case("StringName key with identical text and arity", {"word": 1}, {StringName("word"): 1}, false)
	_reference_case("dictionary insertion order", {"left": [1, 2.0], "right": null}, {"right": null, "left": [1, 2.0]}, true)
	_reference_case("array order", [1, 2.0], [2.0, 1], false)
	var typed: Array[int] = [1, 2, 3]
	_reference_case("typed array metadata", [1, 2, 3], typed, true)
	var typed_dict: Dictionary[String, float] = {"first": 1.0, "second": zero}
	_reference_case("typed dictionary metadata", {"second": zero, "first": 1.0}, typed_dict, true)
	var shared: Dictionary = {"numbers": [null, true, 4, 4.0], "label": "港🙂"}
	_reference_case("alias occurrence shape", [shared, shared], [shared.duplicate(true), shared.duplicate(true)], true)
	_reference_case("same length distinct Unicode", "é", "e", false)
	_reference_case("foreign native vector", [1.0, 2.0, 3.0], Vector3(1, 2, 3), false)
	_reference_case("Object candidate", {"value": null}, {"value": root}, false)
	_reference_case("nonfinite candidate", 1.0, INF, false)
	_reference_case("NaN candidate", 1.0, NAN, false)
	var cycle: Array = []
	cycle.append(cycle)
	_reference_case("same arity cyclic candidate", [[null]], cycle, false)
	cycle.clear()
	var dictionary_cycle: Dictionary = {}
	dictionary_cycle["self"] = dictionary_cycle
	_reference_case("same keys cyclic candidate", {"self": {"self": null}}, dictionary_cycle, false)
	dictionary_cycle.clear()
	var deepest: Variant = null
	for _depth: int in range(Authored.MAX_INPUT_DEPTH): deepest = [deepest]
	_reference_case("depth bound accepted reference", deepest, deepest, true)
	_reference_case("one extra candidate depth", deepest, [deepest], false)
	var entries: Array = []
	entries.resize(Authored.MAX_INPUT_ENTRIES)
	_reference_case("entry bound accepted reference", entries, entries.duplicate(), true)
	var extra: Array = entries.duplicate()
	extra.append(null)
	_reference_case("one extra candidate entry", entries, extra, false)
	var chunk: Array = []
	chunk.resize(16382)
	var aliases: Array = [chunk, chunk, chunk, chunk]
	_reference_case("65533 charged alias occurrences", aliases, [chunk.duplicate(), chunk.duplicate(), chunk.duplicate(), chunk.duplicate()], true)
	var expanded: Array = [null]
	for _depth: int in range(17): expanded = [expanded, expanded]
	_reference_case("expanding candidate exceeds reference shape", aliases, expanded, false)
	var bytes: String = "x".repeat(Authored.MAX_INPUT_BYTES - 16)
	_reference_case("exact ASCII byte bound", bytes, bytes, true)
	_reference_case("ASCII candidate one over bound", bytes, bytes + "x", false)
	var unicode: String = "港".repeat(int((Authored.MAX_INPUT_BYTES - 16) / 3))
	_reference_case("accepted UTF8 byte bound", unicode, unicode, true)
	_reference_case("UTF8 candidate one over bound", unicode, unicode + "港", false)
	_reference_case("oversized candidate leaf", "label", "x".repeat(Authored.MAX_INPUT_BYTES + 1), false)
	_reference_case("oversized candidate key", {"label": 1}, {"x".repeat(Authored.MAX_INPUT_BYTES + 1): 1}, false)
	for index: int in range(16):
		var scalar: float = (float(index) - 8.0) / 7.0
		var reference: Dictionary = {"clock": scalar, "values": [index, float(index), index % 2 == 0, null]}
		var candidate: Dictionary = reference.duplicate(true)
		_reference_case("nested finite copy %d" % index, reference, candidate, true)
		candidate.clock = _next_double(scalar)
		_reference_case("nested finite one bit %d" % index, reference, candidate, false)


func _reference_case(label: String, reference: Variant, candidate: Variant, expected: bool) -> void:
	# Only a currently fully safe reference can license this private path.
	# Never deepcopy/serialize a hostile candidate; public exact_equal walks it
	# with its ORIGINAL bounded refusal before any equality traversal.
	var valid: bool = Authored.exact_equal(reference, reference)
	_expect(valid, label + " reference passes the original complete safety budgets")
	if not valid: return
	var original: bool = Authored.exact_equal(reference, candidate)
	var actual: bool = Authored._same_source_guard_reference(candidate, reference)
	_expect(original == expected and actual == original, label + " reference comparator preserves original exact acceptance")
