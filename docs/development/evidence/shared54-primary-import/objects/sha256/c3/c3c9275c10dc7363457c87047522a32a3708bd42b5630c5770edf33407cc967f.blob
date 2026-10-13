extends "res://tests/authored_enemy_sequence_smoke.gd"
## TEST ONLY same-call validation compatibility. Actual arena helpers supply
## genuine floor/collision descriptors; no lease, damage or campaign acceptance.
## The root codec still owns syntax only; actual native binding is separate.

class DerivedOutputProbe:
	extends "res://scripts/combat/authored_enemy_sequence.gd"
	# Explicit TEST ONLY malformed post-resolution output. Every resolution
	# still calls the actual Difficulty path; no runtime profile file is changed.
	var fault_branch: String = ""
	var resolve_calls: int = 0

	func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:
		resolve_calls += 1
		var result: Dictionary = super._resolve(definition, profile_id)
		if fault_branch == "resolved_role" and resolve_calls == 2:
			result.damage = NAN
		return result

	func _authored(definition: Dictionary, resolved: Dictionary) -> Dictionary:
		var result: Dictionary = super._authored(definition, resolved)
		if fault_branch == "authored": result.inter_echo_gap_s = NAN
		return result

	func _timeline(sequence_id: String, source_id: String, source_epoch: String, generation: int, profile_id: String, definition: Dictionary, resolved: Dictionary, authored: Dictionary) -> Dictionary:
		var result: Dictionary = super._timeline(sequence_id, source_id, source_epoch, generation, profile_id, definition, resolved, authored)
		if fault_branch == "timeline": result.warning_from_s = NAN
		return result


func _run() -> void:
	var arena: Dictionary = await _arena()
	var sequence = Authored.new()
	var configured: bool = sequence.configure(SEQUENCE_ID, _definition(arena.source.global_position), SOURCE_ID, EPOCH, GENERATION, "standard", _world_guards(arena))
	_expect(configured, "canonical seed uses genuine native world/floor descriptors: " + sequence.last_error)
	if configured:
		var seed: Dictionary = sequence.snapshot_state()
		_snapshot_case(sequence, "canonical program", seed, true)
		_snapshot_case(sequence, "dictionary insertion order", _reverse_order(seed), true)
		var typed: Dictionary = seed.duplicate(true)
		var authored_metadata: Dictionary[String, Variant] = {}
		authored_metadata.assign(seed.authored)
		typed.authored = authored_metadata
		_snapshot_case(sequence, "typed dictionary metadata remains transport-neutral", typed, true)
		_branch_cases(sequence, seed)
		_root_cases(sequence, seed)
		_right_cases(seed)
		_public_boundaries()
	await _dispose(arena)
	print("Authored subtree reuse smoke: %d checks, %d failures; exact root/branch/oracle compatibility only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _branch_cases(sequence, seed: Dictionary) -> void:
	var negative_zero: float = PackedByteArray([0, 0, 0, 0, 0, 0, 0, 128]).decode_double(0)
	_expect(_float_bytes(negative_zero)[7] == 128 and negative_zero == 0.0, "signed-zero controls carry a genuine native negative bit")
	for branch: String in ["resolved_role", "authored", "timeline"]:
		var signed: Dictionary = seed.duplicate(true)
		var numeric_type: Dictionary = seed.duplicate(true)
		var one_bit: Dictionary = seed.duplicate(true)
		match branch:
			"resolved_role":
				signed.resolved_role.raw_role.move_speed = negative_zero
				numeric_type.resolved_role.difficulty_schema = float(seed.resolved_role.difficulty_schema)
				one_bit.resolved_role.damage = _one_bit(float(seed.resolved_role.damage))
			"authored":
				signed.authored.inter_echo_gap_s = negative_zero
				numeric_type.authored.inter_echo_gap_s = 0
				one_bit.authored.warning_s = _one_bit(float(seed.authored.warning_s))
			"timeline":
				signed.timeline.warning_from_s = negative_zero
				numeric_type.timeline.slots[0].slot_id = float(seed.timeline.slots[0].slot_id)
				one_bit.timeline.playback_from_s = _one_bit(float(seed.timeline.playback_from_s))
		_snapshot_case(sequence, branch + " signed zero", signed, false)
		_snapshot_case(sequence, branch + " equal number/different type", numeric_type, false)
		_snapshot_case(sequence, branch + " one binary64 bit", one_bit, false)
		var non_string: Dictionary = seed.duplicate(true)
		non_string[branch][StringName("foreign-key")] = null
		_snapshot_case(sequence, branch + " StringName key root refusal", non_string, false)
		var foreign := Node.new()
		var object_case: Dictionary = seed.duplicate(true)
		object_case[branch]["foreign"] = foreign
		_snapshot_case(sequence, branch + " live object root refusal", object_case, false)
		foreign.free()
		_snapshot_case(sequence, branch + " freed object root refusal", object_case, false)
		object_case[branch].erase("foreign")
		var cyclic: Dictionary = seed.duplicate(true)
		cyclic[branch]["self"] = cyclic[branch]
		_snapshot_case(sequence, branch + " cycle root refusal", cyclic, false)
		cyclic[branch].erase("self") # Never deep-copy or stringify hostile inputs.
		var nonfinite: Dictionary = seed.duplicate(true)
		nonfinite[branch]["foreign"] = INF
		_snapshot_case(sequence, branch + " nonfinite root refusal", nonfinite, false)


func _root_cases(sequence, seed: Dictionary) -> void:
	# Full snapshot -> branch -> value has offset 2. A null leaf exactly at32
	# passes the root walk, although its extra authored field later fails schema.
	var deepest: Variant = null
	for _index: int in range(Authored.MAX_INPUT_DEPTH - 2): deepest = [deepest]
	var at_depth: Dictionary = seed.duplicate(true)
	at_depth.authored["extra"] = deepest
	_expect(Authored._safe_json_error(at_depth).is_empty(), "complete snapshot root admits its exact logical depth 32 boundary")
	_snapshot_case(sequence, "safe maximum-depth extra branch still fails canonical derivation", at_depth, false)
	at_depth.authored.extra = [deepest]
	_expect(Authored._safe_json_error(at_depth) == "Authored transport exceeds bounded depth/node/byte budget", "complete root depth 33 is refused before branch comparison")
	_snapshot_case(sequence, "root depth 33", at_depth, false)
	var expansion: Array = [null]
	for _index: int in range(17): expansion = [expansion, expansion]
	var global_case: Dictionary = seed.duplicate(true)
	global_case.authored["extra"] = expansion
	_snapshot_case(sequence, "aliased complete root exceeding global traversal budget", global_case, false)
	var large_array: Array = []
	large_array.resize(Authored.MAX_INPUT_ENTRIES + 1)
	var entries: Dictionary = seed.duplicate(true)
	entries.timeline["extra"] = large_array
	_snapshot_case(sequence, "complete root container entry cap", entries, false)
	var utf8: Dictionary = seed.duplicate(true)
	utf8.resolved_role["extra"] = "港".repeat(int(Authored.MAX_INPUT_BYTES / 3) + 1)
	_snapshot_case(sequence, "complete root UTF8 byte cap", utf8, false)


func _right_cases(seed: Dictionary) -> void:
	for branch: String in ["resolved_role", "authored", "timeline"]:
		var reference := DerivedOutputProbe.new()
		reference.fault_branch = branch
		var expected_error: String = _original_snapshot_error(reference, seed)
		var current := DerivedOutputProbe.new()
		current.fault_branch = branch
		var actual_error: String = current.snapshot_error(seed, EPOCH, GENERATION)
		_expect(not expected_error.is_empty() and actual_error == expected_error, branch + " malformed freshly derived right operand keeps full safety and exact original error")
		_expect(reference.resolve_calls == 2 and current.resolve_calls == 2 and current.snapshot_state().is_empty(), branch + " retains both actual Difficulty resolutions and performs no commit")


func _public_boundaries() -> void:
	# These invoke the unchanged public comparator/root guard, never the private
	# trusted-branch helper. Authored 32/65,536/1 MiB are stricter than Exact64.
	var deepest: Variant = null
	for _index: int in range(Authored.MAX_INPUT_DEPTH): deepest = [deepest]
	_expect(Authored.exact_equal(deepest, deepest), "standalone authored depth 32 remains accepted")
	_expect(not Authored.exact_equal([deepest], [deepest]), "standalone authored depth 33 remains rejected")
	for _index: int in range(Exact.MAX_DEPTH - Authored.MAX_INPUT_DEPTH): deepest = [deepest]
	_expect(not Exact.stringify(deepest).is_empty() and not Authored.exact_equal(deepest, deepest), "Exact logical depth 64 does not widen authored 32")
	_expect(Exact.stringify([deepest]).is_empty(), "Exact logical depth 65 is still rejected independently")
	var chunk: Array = []
	chunk.resize(16383)
	var tail: Array = []
	tail.resize(16382)
	var node_limit: Array = [chunk, chunk, chunk, tail] # 1+4+49,149+16,382 =65,536 nodes.
	_expect(Authored._safe_json_error(node_limit).is_empty() and Authored.exact_equal(node_limit, node_limit), "actual root walk counts aliases and accepts exactly 65,536 null-only logical nodes/1 MiB")
	tail.append(null)
	_expect(not Authored._safe_json_error(node_limit).is_empty() and not Authored.exact_equal(node_limit, node_limit), "one extra logical node remains refused")
	var entry_limit: Array = []
	entry_limit.resize(Authored.MAX_INPUT_ENTRIES)
	_expect(Authored.exact_equal(entry_limit, entry_limit), "standalone container entry bound remains accepted")
	entry_limit.append(null)
	_expect(not Authored.exact_equal(entry_limit, entry_limit), "standalone oversized container remains refused")
	var string_limit: String = "x".repeat(Authored.MAX_INPUT_BYTES - 16)
	_expect(Authored.exact_equal(string_limit, string_limit) and not Authored.exact_equal(string_limit + "x", string_limit + "x"), "standalone raw string byte boundary remains exact")
	_expect(not Authored.exact_equal(Codec.MAX_SAFE_INTEGER + 1, Codec.MAX_SAFE_INTEGER + 1) and not Authored.exact_equal(NAN, NAN), "standalone unsafe integers/nonfinite values remain refused")


func _snapshot_case(sequence, label: String, value: Dictionary, accepted: bool) -> void:
	# Inputs may contain actual Objects, cycles or overbudget aliases: only the
	# unchanged bounded root walker sees them before copying. No hostile stringify.
	var before: String = Exact.stringify(sequence.snapshot_state())
	var diagnostics: Array = [sequence.last_error, sequence.last_snapshot_error]
	var reference = Authored.new()
	var expected_error: String = _original_snapshot_error(reference, value)
	var actual_error: String = sequence.snapshot_error(value, EPOCH, GENERATION)
	_expect(actual_error == expected_error and actual_error.is_empty() == accepted, label + " preserves exact original acceptance/error ordering")
	_expect(not before.is_empty() and before == Exact.stringify(sequence.snapshot_state()) and diagnostics == [sequence.last_error, sequence.last_snapshot_error], label + " validation remains pure for the configured owner")
	var fresh = Authored.new()
	var restored: bool = fresh.restore_state(value, EPOCH, GENERATION)
	_expect(restored == accepted and (not fresh.snapshot_state().is_empty() if accepted else fresh.snapshot_state().is_empty()), label + " actual fresh writer commits only accepted full programs")


func _original_snapshot_error(reader, snapshot: Dictionary) -> String:
	# Literal pre-change validator ordering; calls the unchanged production pure
	# derivation helpers/public comparator. No optimization helper is used here.
	var error: String = Authored._safe_json_error(snapshot)
	if error.is_empty(): error = Codec.keys_error(snapshot, Authored.HEADER_KEYS)
	if not error.is_empty(): return error
	if not snapshot.api_revision is String or not snapshot.provenance is String or not snapshot.source_epoch is String or snapshot.api_revision != Authored.API_REVISION or typeof(snapshot.schema_version) != TYPE_INT or snapshot.schema_version != 1 or snapshot.provenance != "enemy_authored" or snapshot.source_epoch != EPOCH or typeof(snapshot.generation) != TYPE_INT or snapshot.generation != GENERATION:
		return "Authored enemy API/provenance/epoch/generation differs"
	if not snapshot.definition is Dictionary or not snapshot.resolved_role is Dictionary or not snapshot.world is Dictionary or not snapshot.authored is Dictionary or not snapshot.timeline is Dictionary:
		return "Closed authored enemy definition/role/world/timetable required"
	error = reader._input_error(snapshot.sequence_id, snapshot.definition, snapshot.source_id, EPOCH, GENERATION, snapshot.profile_id, snapshot.world)
	if not error.is_empty(): return error
	var resolved: Dictionary = reader._resolve(snapshot.definition, snapshot.profile_id)
	var authored: Dictionary = reader._authored(snapshot.definition, resolved)
	if not Authored.exact_equal(snapshot.resolved_role, resolved) or not Authored.exact_equal(snapshot.authored, authored) or not Authored.exact_equal(snapshot.timeline, reader._timeline(snapshot.sequence_id, snapshot.source_id, EPOCH, GENERATION, snapshot.profile_id, snapshot.definition, resolved, authored)):
		return "Role, compact timeline and every enemy action must derive exactly from the immutable definition"
	return ""


func _reverse_order(value: Variant) -> Variant:
	if value is Array:
		var array: Array = []
		for child: Variant in value: array.append(_reverse_order(child))
		return array
	if value is Dictionary:
		var result: Dictionary = {}
		var keys: Array = value.keys()
		keys.reverse()
		for key: String in keys: result[key] = _reverse_order(value[key])
		return result
	return value


func _float_bytes(value: float) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	return bytes
