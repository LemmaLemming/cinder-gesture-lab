extends "res://tests/authored_enemy_sequence_smoke.gd"
## TEST ONLY equality compatibility. Native helpers construct one genuine
## authored program/floor descriptor; this is not admission or gameplay proof.
## Legacy stringify is called ONLY for known finite, acyclic, bounded JSON.
## Hostile/native/cyclic inputs exercise only the production safe comparator.


func _run() -> void:
	var arena: Dictionary = await _arena()
	var sequence = Authored.new()
	var accepted: bool = sequence.configure(SEQUENCE_ID, _definition(arena.source.global_position), SOURCE_ID, EPOCH, GENERATION, "standard", _world_guards(arena))
	_expect(accepted, "representative canonical authored program uses genuine native world/floor descriptors: " + sequence.last_error)
	if accepted:
		var program: Dictionary = sequence.snapshot_state()
		_valid_cases(program)
		_budget_cases()
		_hostile_cases()
		_timing(program)
	await _dispose(arena)
	print("Authored exact comparison smoke: %d checks, %d failures; bounded legacy serializer compatibility and diagnostic timing only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _valid_cases(program: Dictionary) -> void:
	_case("canonical program copy", program, program.duplicate(true), true)
	_case("recursive dictionary insertion order", program, _reverse_keys(program), true)
	var changed: Dictionary = program.duplicate(true)
	changed.timeline.slots[0].events[0].record["damage"] = _one_bit(float(changed.timeline.slots[0].events[0].record.damage))
	_case("one binary64 bit in canonical program transport", program, changed, false)
	changed = program.duplicate(true)
	changed["generation"] = float(changed.generation)
	_case("equal numeric but different generation type", program, changed, false)
	_case("ordered arrays", [null, true, 2, 2.0], [true, null, 2, 2.0], false)
	_case("integer versus float", 1, 1.0, false)
	_case("boolean versus integer", false, 0, false)
	_case("string versus integer", "1", 1, false)
	_case("null versus empty dictionary", null, {}, false)
	_case("safe integer endpoints", [-Codec.MAX_SAFE_INTEGER, Codec.MAX_SAFE_INTEGER], [-Codec.MAX_SAFE_INTEGER, Codec.MAX_SAFE_INTEGER], true)
	var negative_zero: float = PackedByteArray([0, 0, 0, 0, 0, 0, 0, 128]).decode_double(0)
	var positive_zero: float = PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0]).decode_double(0)
	_expect(negative_zero == positive_zero, "signed-zero control has numeric equality despite different native binary64 bits")
	_case("positive versus negative zero", positive_zero, negative_zero, false)
	_case("negative zero copy", negative_zero, negative_zero, true)
	var subnormal: float = PackedByteArray([1, 0, 0, 0, 0, 0, 0, 0]).decode_double(0)
	_case("smallest positive subnormal versus zero", subnormal, positive_zero, false)
	_case("smallest positive subnormal copy", subnormal, subnormal, true)
	var typed_array: Array[int] = [1, 2, 3]
	_case("typed array metadata is not JSON identity", typed_array, [1, 2, 3], true)
	var typed_dictionary: Dictionary[String, float] = {"first": 1.0, "second": negative_zero}
	_case("typed dictionary metadata is not JSON identity", typed_dictionary, {"second": negative_zero, "first": 1.0}, true)
	var shared: Dictionary = {"typed": [null, true, 4, 4.0], "label": "shared"}
	_case("aliased acyclic JSON versus independent copies", [shared, shared], [shared.duplicate(true), shared.duplicate(true)], true)
	var controls: String = ""
	for code: int in range(1, 32): controls += String.chr(code)
	var unicode_text: String = "港🙂" + String.chr(0x2028) + String.chr(0x2029) + String.chr(0xfffd)
	var slash_text: String = "C:\\route\\v\\u000b\\\\quoted\"line\n"
	_case("all native non-NUL C0 controls and Unicode", {"controls": controls, "unicode": unicode_text, "slashes": slash_text}, {"slashes": slash_text, "unicode": unicode_text, "controls": controls}, true)
	_case("literal backslash-v versus actual vertical tab", "\\v", String.chr(11), false)
	_case("literal escape text versus actual control", "\\u000b", String.chr(11), false)
	_case("composed versus decomposed Unicode stays distinct", "é", "e" + String.chr(0x301), false)
	# 96 deterministic nested scalar comparisons: same exact bits/types versus
	# a real one-bit binary64 change. No random state, rounding tolerance or hash.
	for index: int in range(48):
		var scalar: float = (float(index) - 24.0) / 7.0
		var left: Dictionary = {"clock": scalar, "values": [index, float(index), index % 2 == 0, null], "nested": {"text": unicode_text + str(index), "slashes": slash_text}}
		_case("deterministic nested copy %d" % index, left, _reverse_keys(left), true)
		var right: Dictionary = left.duplicate(true)
		right["clock"] = _one_bit(scalar)
		_case("deterministic nested one-bit %d" % index, left, right, false)


func _budget_cases() -> void:
	var deepest: Variant = null
	for _level: int in range(Authored.MAX_INPUT_DEPTH): deepest = [deepest]
	_case("maximum supported logical depth", deepest, deepest, true)
	var too_deep: Array = [deepest]
	_reject("depth one above bound", too_deep)
	var at_entries: Array = []
	at_entries.resize(Authored.MAX_INPUT_ENTRIES)
	_case("array at entry bound", at_entries, at_entries, true)
	var over_entries: Array = []
	over_entries.resize(Authored.MAX_INPUT_ENTRIES + 1)
	_reject("array one above entry bound", over_entries)
	var over_dictionary: Dictionary = {}
	for index: int in range(Authored.MAX_INPUT_ENTRIES + 1): over_dictionary[str(index)] = null
	_reject("dictionary one above entry bound", over_dictionary)
	# Global traversal counts each alias occurrence. The 16-byte/node lower
	# bound and 65,536-node limit meet here; neither per-container size nor DAG
	# identity may incorrectly license an expanding logical tree.
	var chunk: Array = []
	chunk.resize(16382)
	var within_global: Array = [chunk, chunk, chunk, chunk] # 65,533 logical nodes.
	_case("aliased tree below global node/byte bound", within_global, within_global, true)
	var expansion: Array = [null]
	for _level: int in range(17): expansion = [expansion, expansion]
	_reject("aliased tree beyond global node/byte bound", expansion)
	var at_bytes: String = "x".repeat(Authored.MAX_INPUT_BYTES - 16)
	_case("ASCII at authored raw byte bound", at_bytes, at_bytes, true)
	_reject("ASCII one above authored raw byte bound", at_bytes + "x")
	var multibyte: String = "港".repeat(int((Authored.MAX_INPUT_BYTES - 16) / 3))
	_case("UTF8 bytes below authored bound", multibyte, multibyte, true)
	_reject("UTF8 byte budget cannot use character count", multibyte + "港")
	_reject("single oversized string", "x".repeat(Authored.MAX_INPUT_BYTES + 1))


func _hostile_cases() -> void:
	_reject("unsafe positive integer", Codec.MAX_SAFE_INTEGER + 1)
	_reject("unsafe negative integer", -Codec.MAX_SAFE_INTEGER - 1)
	_reject("NaN", NAN)
	_reject("positive infinity", INF)
	_reject("negative infinity", -INF)
	_reject("integer dictionary key", {1: "value"})
	_reject("StringName dictionary key", {StringName("key"): "value"})
	_reject("native Vector3", Vector3.ZERO)
	_reject("native packed bytes", PackedByteArray([1, 2, 3]))
	var object := Node.new()
	var object_branch: Dictionary = {"object": object}
	_reject("live native object", object)
	_reject("live native object in JSON branch", object_branch)
	object.free()
	_reject("actually freed native object handle", object_branch)
	object_branch.clear()
	var cycle_array: Array = []
	cycle_array.append(cycle_array)
	_reject("self-referencing Array", cycle_array)
	cycle_array.clear() # Break deliberate reference cycle; never stringify it.
	var cycle_dictionary: Dictionary = {}
	cycle_dictionary["self"] = cycle_dictionary
	_reject("self-referencing Dictionary", cycle_dictionary)
	cycle_dictionary.erase("self")
	var mixed_array: Array = []
	var mixed_dictionary: Dictionary = {"array": mixed_array}
	mixed_array.append(mixed_dictionary)
	_reject("mixed Array/Dictionary cycle", mixed_dictionary)
	mixed_array.clear()
	mixed_dictionary.clear()


func _case(label: String, left: Variant, right: Variant, expected: bool) -> void:
	# All callers above construct only known finite, acyclic JSON within the
	# unchanged Authored budgets. Never route hostile controls through this oracle.
	var legacy: bool = _legacy_bounded_equal(left, right)
	_expect(legacy == expected, label + " retained tagged serializer reference has the declared exact result")
	_expect(Authored.exact_equal(left, right) == legacy and Authored.exact_equal(right, left) == legacy, label + " production equality matches the reference in both directions")


func _legacy_bounded_equal(left: Variant, right: Variant) -> bool:
	# Retain the original implementation, including its unchanged safety walks.
	# Only known accepted controls/programs reach this helper or timing loop.
	if not Authored._safe_json_error(left).is_empty() or not Authored._safe_json_error(right).is_empty(): return false
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _reject(label: String, value: Variant) -> void:
	# No legacy stringify/deep copy of objects, cycles, foreign containers or
	# overbudget trees. Self comparison also prevents a cheap identity shortcut.
	_expect(not Authored.exact_equal(value, value) and not Authored.exact_equal(value, null) and not Authored.exact_equal(null, value), label + " stays fail-closed under unchanged authored safety")


func _reverse_keys(value: Variant) -> Variant:
	# Known acyclic accepted controls only; dictionary insertion order changes,
	# ordered arrays and all primitive native types/bits remain unchanged.
	if value is Array:
		var entries: Array = []
		for child: Variant in value: entries.append(_reverse_keys(child))
		return entries
	if value is Dictionary:
		var result: Dictionary = {}
		var keys: Array = value.keys()
		keys.reverse()
		for key: String in keys: result[key] = _reverse_keys(value[key])
		return result
	return value


func _timing(program: Dictionary) -> void:
	var copied: Dictionary = program.duplicate(true)
	var iterations: int = 40
	# Diagnostic samples; no machine-speed assertion or gameplay/FPS claim.
	_expect(_legacy_bounded_equal(program, copied) and Authored.exact_equal(program, copied), "both timed functions accept the same actual canonical authored program")
	var start_us: int = Time.get_ticks_usec()
	var legacy_ok: bool = true
	for _index: int in range(iterations): legacy_ok = _legacy_bounded_equal(program, copied) and legacy_ok
	var legacy_us: int = Time.get_ticks_usec() - start_us
	start_us = Time.get_ticks_usec()
	var current_ok: bool = true
	for _index: int in range(iterations): current_ok = Authored.exact_equal(program, copied) and current_ok
	var current_us: int = Time.get_ticks_usec() - start_us
	_expect(legacy_ok and current_ok, "diagnostic timing loops preserve the same exact accepted result")
	print("TEST ONLY canonical authored equality diagnostic: iterations=%d legacy_total_us=%d current_total_us=%d; both include the unchanged safety walks; elapsed samples are not a performance threshold or native gameplay result" % [iterations, legacy_us, current_us])
