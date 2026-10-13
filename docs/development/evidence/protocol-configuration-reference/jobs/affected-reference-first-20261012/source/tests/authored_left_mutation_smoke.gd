extends "res://tests/authored_enemy_sequence_smoke.gd"
## TEST ONLY post-root mutation/subclass regression; native evidence preserves
## the original pre-run bytes under Shared36 runtime validation originals.
## TEST ONLY virtual derivation mutates its own submitted snapshot alias after
## the unchanged root walk. RHS still comes from actual super derivations.
## Use only after the integration owner installs a reviewed codec candidate.

const DERIVATION_ERROR: String = "Role, compact timeline and every enemy action must derive exactly from the immutable definition"

class DerivedOutputProbe:
	extends "res://scripts/combat/authored_enemy_sequence.gd"
	# Preserve the existing legitimate TEST subclass's malformed-RHS controls.
	var fault_branch: String = ""
	var resolve_calls: int = 0

	func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:
		resolve_calls += 1
		var result: Dictionary = super._resolve(definition, profile_id)
		if fault_branch == "resolved_role" and resolve_calls == 2: result.damage = NAN
		return result

	func _authored(definition: Dictionary, resolved: Dictionary) -> Dictionary:
		var result: Dictionary = super._authored(definition, resolved)
		if fault_branch == "authored": result.inter_echo_gap_s = NAN
		return result

	func _timeline(sequence_id: String, source_id: String, source_epoch: String, generation: int, profile_id: String, definition: Dictionary, resolved: Dictionary, authored: Dictionary) -> Dictionary:
		var result: Dictionary = super._timeline(sequence_id, source_id, source_epoch, generation, profile_id, definition, resolved, authored)
		if fault_branch == "timeline": result.warning_from_s = NAN
		return result

class LeftMutationProbe:
	extends "res://scripts/combat/authored_enemy_sequence.gd"
	var submitted: Dictionary = {}
	var fault_branch: String = ""
	var fault_mode: String = ""
	var resolve_calls: int = 0
	var mutations: int = 0
	var held_object: Node = null
	var original_value: Variant
	var original_key: String = ""

	func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:
		resolve_calls += 1
		var result: Dictionary = super._resolve(definition, profile_id)
		if fault_branch == "resolved_role" and resolve_calls == 2:
			_mutate("resolved_role", "damage")
		return result

	func _authored(definition: Dictionary, resolved: Dictionary) -> Dictionary:
		var result: Dictionary = super._authored(definition, resolved)
		if fault_branch == "authored": _mutate("authored", "inter_echo_gap_s")
		return result

	func _timeline(sequence_id: String, source_id: String, source_epoch: String, generation: int, profile_id: String, definition: Dictionary, resolved: Dictionary, authored: Dictionary) -> Dictionary:
		var result: Dictionary = super._timeline(sequence_id, source_id, source_epoch, generation, profile_id, definition, resolved, authored)
		if fault_branch == "timeline": _mutate("timeline", "warning_from_s")
		return result

	func _mutate(branch: String, key: String) -> void:
		if fault_mode.is_empty() or mutations != 0: return
		var left: Dictionary = submitted[branch]
		original_key = key
		original_value = left[key]
		mutations += 1
		match fault_mode:
			"string_name_key":
				left.erase(key)
				left[StringName(key)] = original_value
			"unsafe_extra_key":
				left[37] = null
			"object_value":
				held_object = Node.new()
				left[key] = held_object
			"cycle_value":
				left[key] = left
			"oversized_value":
				left[key] = "x".repeat(MAX_INPUT_BYTES + 1)
			"different_closed_value":
				left[key] = float(original_value) + 1.0

	func cleanup() -> void:
		# Do not deepcopy/stringify the injected hostile graph. Break the cycle
		# and release a genuine Object only after each validator has returned.
		if mutations != 0:
			var left: Dictionary = submitted[fault_branch]
			left.erase(StringName(original_key))
			left.erase(37)
			left[original_key] = original_value
		if is_instance_valid(held_object): held_object.free()
		held_object = null
		submitted = {}


func _run() -> void:
	_native_key_controls()
	var arena: Dictionary = await _arena()
	var seed_owner = Authored.new()
	_expect(CinderAuthoredEnemySequence is Script and seed_owner.get_script() == CinderAuthoredEnemySequence and seed_owner.get_script() == Authored, "the actual exact codec self-class is the same native Script resource, without a self preload or loader call")
	var subclass = LeftMutationProbe.new()
	_expect(subclass.get_script() != CinderAuthoredEnemySequence and (subclass.get_script() as Script).get_base_script() == Authored, "a legitimate virtual subclass fails the same exact native Script predicate used before derivations")
	var rhs_subclass = DerivedOutputProbe.new()
	_expect(rhs_subclass.get_script() != CinderAuthoredEnemySequence, "the existing malformed-RHS subclass also selects original full comparisons")
	var configured: bool = seed_owner.configure(SEQUENCE_ID, _definition(arena.source.global_position), SOURCE_ID, EPOCH, GENERATION, "standard", _world_guards(arena))
	_expect(configured, "canonical seed is the actual codec with genuine native floor/collision descriptors: " + seed_owner.last_error)
	if configured:
		var seed: Dictionary = seed_owner.snapshot_state()
		_expect(Authored._safe_json_error(seed).is_empty(), "every submitted seed passes the whole root walk before a virtual hook")
		_expect(seed_owner.snapshot_error(seed, EPOCH, GENERATION).is_empty(), "exact production Script retains the ordinary canonical positive case")
		for branch: String in ["resolved_role", "authored", "timeline"]:
			_case(seed, branch, "")
			for mode: String in ["string_name_key", "unsafe_extra_key", "object_value", "cycle_value", "oversized_value", "different_closed_value"]:
				_case(seed, branch, mode)
		_derived_right_cases(seed)
	await _dispose(arena)
	print("Authored LEFT mutation oracle smoke: %d checks, %d failures; TEST ONLY subclass compatibility, no runtime/performance claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _native_key_controls() -> void:
	var native: Dictionary = {}
	native[StringName("damage")] = 2.0
	var original_key: Variant = native.keys()[0]
	_expect(typeof(original_key) == TYPE_STRING_NAME and native.has("damage") and native["damage"] == 2.0, "genuine StringName dictionary key is content-compatible with a String lookup")
	var visited: Array[String] = []
	for key: String in native: visited.append(key)
	_expect(visited == ["damage"], "the exact comparator's typed String iterator converts the genuine StringName key")
	_expect(not Authored._safe_json_error(native).is_empty() and not Authored.exact_equal(native, {"damage": 2.0}), "unchanged public comparator rejects the actual non-String transport key")


func _case(seed: Dictionary, branch: String, mode: String) -> void:
	var original = LeftMutationProbe.new()
	original.submitted = seed.duplicate(true)
	original.fault_branch = branch
	original.fault_mode = mode
	var current = LeftMutationProbe.new()
	current.submitted = seed.duplicate(true)
	current.fault_branch = branch
	current.fault_mode = mode
	_expect(Authored._safe_json_error(original.submitted).is_empty() and Authored._safe_json_error(current.submitted).is_empty(), branch + "/" + mode + " starts as a closed bounded snapshot")
	var expected: String = _original_snapshot_error(original, original.submitted)
	var actual: String = current.snapshot_error(current.submitted, EPOCH, GENERATION)
	var accepted: bool = mode.is_empty()
	_expect(expected == ("" if accepted else DERIVATION_ERROR), branch + "/" + mode + " original literal ordering provides a rejecting oracle for post-walk mutation")
	_expect(actual == expected, branch + "/" + mode + " candidate preserves the original public subclass acceptance and error")
	_expect(original.resolve_calls == 2 and current.resolve_calls == 2 and original.mutations == (0 if accepted else 1) and current.mutations == original.mutations, branch + "/" + mode + " uses genuine super derivations at the intended same-call boundary")
	_expect(current.snapshot_state().is_empty() and current.last_error.is_empty() and current.last_snapshot_error.is_empty(), branch + "/" + mode + " pure validation leaves the reader wire and diagnostics untouched")
	if mode == "string_name_key":
		_expect(_has_string_name_key(original.submitted[branch]) and _has_string_name_key(current.submitted[branch]), branch + " actual key type was replaced after the root walk")
	original.cleanup()
	current.cleanup()
	var writer = LeftMutationProbe.new()
	writer.submitted = seed.duplicate(true)
	writer.fault_branch = branch
	writer.fault_mode = mode
	var restored: bool = writer.restore_state(writer.submitted, EPOCH, GENERATION)
	_expect(restored == accepted and (not writer.snapshot_state().is_empty() if accepted else writer.snapshot_state().is_empty()), branch + "/" + mode + " fresh real writer commits only the oracle-accepted program")
	_expect(writer.last_snapshot_error == expected, branch + "/" + mode + " restore retains the exact original validation error")
	writer.cleanup()


func _has_string_name_key(value: Dictionary) -> bool:
	for key: Variant in value:
		if typeof(key) == TYPE_STRING_NAME: return true
	return false


func _derived_right_cases(seed: Dictionary) -> void:
	for branch: String in ["resolved_role", "authored", "timeline"]:
		var original = DerivedOutputProbe.new()
		original.fault_branch = branch
		var current = DerivedOutputProbe.new()
		current.fault_branch = branch
		var expected: String = _original_snapshot_error(original, seed)
		var actual: String = current.snapshot_error(seed, EPOCH, GENERATION)
		_expect(expected == DERIVATION_ERROR and actual == expected, branch + " malformed RHS preserves the original legitimate subclass error")
		_expect(original.resolve_calls == 2 and current.resolve_calls == 2 and current.snapshot_state().is_empty(), branch + " malformed RHS retains original actual derivation counts and no commit")


func _original_snapshot_error(reader, snapshot: Dictionary) -> String:
	# Literal pre-optimization ordering, using unchanged actual public safety
	# walks and the SAME virtual callbacks as the candidate. No fake codec.
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
		return DERIVATION_ERROR
	return ""
