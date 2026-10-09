#!/usr/bin/env python3
"""OFFLINE source generation only. Never installs or launches any candidate."""
from pathlib import Path
import difflib
import hashlib
import json
import re


def main() -> None:
    directory = Path(__file__).resolve().parent
    root = directory.parent.parent
    prior = root / ".cinder/runtime-source-reuse-rebased35"
    frozen = json.loads((directory / "frozen-inputs-before.json").read_text())
    for path, receipt in {**frozen["live"], **frozen["prior_frozen"]}.items():
        value = (root / path).read_bytes()
        assert len(value) == receipt["bytes"] and hashlib.sha256(value).hexdigest() == receipt["sha256"], path

    # The original native String parser remains unchanged; only its exact
    # parser-text dependency is privately copied for optional same-call reuse.
    (directory / "difficulty.gd").write_bytes((prior / "difficulty.gd").read_bytes())

    authored = (directory / "authored_enemy_sequence.original.gd").read_text()
    authored = authored.replace(
        'var _json: Dictionary = {}\n',
        'var _json: Dictionary = {}\n'
        '## Private one-call parser dependency; never serialized/native authority.\n'
        'var _validation_input := PackedByteArray()\n'
        '## Temporary sink armed ONLY by a fresh exact-native internal reader.\n'
        '## Detached on every return BEFORE the Scheduler calls its source hook.\n'
        'var _source_guard_inputs: Variant = null\n', 1)

    old_resolve = '''func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:
	return Difficulty.new().resolve_role(definition.raw_role, profile_id, definition.timing_floors)
'''
    new_resolve = '''func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:
	var difficulty = Difficulty.new()
	var resolved: Dictionary = difficulty.resolve_role(definition.raw_role, profile_id, definition.timing_floors)
	# Preserve the original virtual signature/arity and both independent reads.
	# Public calls and subclasses never arm this exact-native factory's sink.
	if _source_guard_inputs is Array:
		_source_guard_inputs.append(difficulty._catalogue_validation_input())
	return resolved
'''
    assert authored.count(old_resolve) == 1
    authored = authored.replace(old_resolve, new_resolve, 1)

    old = (prior / "authored_enemy_sequence.gd").read_text()
    start = old.index('## Internal Scheduler source-error preparation only.')
    end = old.index('\n\nstatic func exact_equal', start)
    private = old[start:end]
    old_factory = '''func _restore_for_source_guard(snapshot: Dictionary, source_epoch: String, generation: int) -> bool:
	if not _json.is_empty():
		last_snapshot_error = "Fresh source-guard reader required"
		return false
	_validation_input = PackedByteArray()
	var validation_inputs: Array = []
	last_snapshot_error = _snapshot_error_with_inputs(snapshot, source_epoch, generation, validation_inputs)
	if not last_snapshot_error.is_empty():
		return false
	_json = snapshot.duplicate(true)
	_validation_input = _shared_validation_input(validation_inputs)
	last_error = ""
	return true
'''
    new_factory = '''func _restore_for_source_guard(snapshot: Dictionary, source_epoch: String, generation: int) -> bool:
	# Only Scheduler's local fresh Program reader calls this. No subclass may
	# collect dependencies around virtual callbacks or supply accepted flags.
	if get_script() != CinderAuthoredEnemySequence or not _json.is_empty() or _source_guard_inputs != null or not _validation_input.is_empty():
		last_snapshot_error = "Fresh exact-native source-guard reader required"
		return false
	var validation_inputs: Array = []
	_source_guard_inputs = validation_inputs
	# ORIGINAL public restore/snapshot_error bodies, signatures and call order.
	var restored: bool = restore_state(snapshot, source_epoch, generation)
	# No return, hook, callback or yield intervenes before detaching the sink.
	_source_guard_inputs = null
	if not restored:
		_validation_input = PackedByteArray()
		return false
	_validation_input = _shared_validation_input(validation_inputs)
	return true
'''
    assert private.count(old_factory) == 1
    private = private.replace(old_factory, new_factory, 1)
    private = private.replace(
        'var reuse: bool = not validation_input.is_empty()',
        'var reuse: bool = get_script() == CinderAuthoredEnemySequence and _source_guard_inputs == null and not validation_input.is_empty()', 1)
    authored = authored.replace('\n\nstatic func exact_equal', '\n\n' + private + '\n\nstatic func exact_equal', 1)
    (directory / "authored_enemy_sequence.gd").write_text(authored)

    # Keep all original reader public methods, captured branch and writer
    # signatures unchanged; only a fresh local internal factory is added.
    program = (prior / "replay_program.gd").read_text()
    program = program.replace(
        'if _reader != null or not _kind.is_empty():\n\t\tlast_snapshot_error = "Fresh source-guard reader required"',
        'if get_script() != CinderReplayProgram or _reader != null or not _kind.is_empty():\n\t\tlast_snapshot_error = "Fresh exact-native source-guard reader required"', 1)
    (directory / "replay_program.gd").write_text(program)

    # This is the previous minimal cost hunk already rebased to owner-guard35:
    # one local reader preparation and one immediate private consuming tail.
    # No ordinary admission, lifecycle, callback or native/world guard changes.
    (directory / "threat_scheduler.gd").write_bytes((prior / "threat_scheduler.gd").read_bytes())

    fixture = (prior / "source_reuse_smoke.gd").read_text()
    probe = '''class OriginalSignatureProbe extends "res://scripts/combat/authored_enemy_sequence.gd":
	var input_calls: int = 0
	var resolve_calls: int = 0

	func _input_error(sequence_id: Variant, definition: Dictionary, source_id: Variant, source_epoch: String, generation: int, profile_id: Variant, world: Dictionary) -> String:
		input_calls += 1
		return super._input_error(sequence_id, definition, source_id, source_epoch, generation, profile_id, world)

	func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:
		resolve_calls += 1
		return super._resolve(definition, profile_id)

'''
    fixture = fixture.replace('class GetterActor extends', probe + 'class GetterActor extends', 1)
    fixture = fixture.replace('\t_watch(arena)\n', '\t_test_original_signatures(arena.actor.source_program())\n\t_watch(arena)\n', 1)
    test = '''func _test_original_signatures(program: Dictionary) -> void:
	var subclass = OriginalSignatureProbe.new()
	_expect(subclass.get_script() != ReusePlan, "legitimate old-signature subclass differs from the native shared Script")
	_expect(subclass.snapshot_error(program, EPOCH, GENERATION).is_empty() and subclass.input_calls == 1 and subclass.resolve_calls == 2, "original seven/two-argument virtual overrides parse and dispatch in the same order/count")
	subclass.input_calls = 0
	subclass.resolve_calls = 0
	_expect(subclass.restore_state(program, EPOCH, GENERATION) and subclass.input_calls == 1 and subclass.resolve_calls == 2 and subclass.get("_source_guard_inputs") == null, "public subclass restore keeps its original virtual dispatch and never collects a receipt")
	var fresh_subclass = OriginalSignatureProbe.new()
	_expect(not fresh_subclass._restore_for_source_guard(program, EPOCH, GENERATION) and fresh_subclass.input_calls == 0 and fresh_subclass.resolve_calls == 0 and fresh_subclass.snapshot_state().is_empty(), "exact-native internal collection refuses subclasses before any virtual dispatch or wire commit")
	var native = ReusePlan.new()
	_expect(native._restore_for_source_guard(program, EPOCH, GENERATION) and native.get("_source_guard_inputs") == null and ReusePlan.exact_equal(native.snapshot_state(), program), "successful fresh native preparation detaches the sink before returning to any source hook")
	var malformed: Dictionary = program.duplicate(true)
	malformed.source_epoch = "different-epoch"
	var rejected = ReusePlan.new()
	_expect(not rejected._restore_for_source_guard(malformed, EPOCH, GENERATION) and rejected.get("_source_guard_inputs") == null and rejected.get("_validation_input").is_empty() and rejected.snapshot_state().is_empty(), "failed native preparation also detaches and clears every private dependency before returning")
	var public_native = ReusePlan.new()
	_expect(public_native.restore_state(program, EPOCH, GENERATION) and public_native.get("_source_guard_inputs") == null and public_native.get("_validation_input").is_empty(), "ordinary native public restore retains no source-guard receipt")


'''
    fixture = fixture.replace('func _arena(extreme:', test + 'func _arena(extreme:', 1)
    fixture = fixture.replace('var before: String = Exact.stringify(initial)\n', 'var before: String = Exact.stringify(initial)\n\t_expect(not before.is_empty(), mode + " actual pre-boundary receipt encodes completely")\n\tif before.is_empty(): return\n', 1)
    fixture = fixture.replace(
        '\t\t_expect(_callbacks.is_empty() and Exact.stringify(_native_unit(arena)) == before,',
        '\t\tvar after: String = Exact.stringify(_native_unit(arena))\n\t\t_expect(not after.is_empty() and _callbacks.is_empty() and after == before,', 1)
    for field, expression in {
        "source_instance": "arena.actor.get_instance_id()",
        "source_script": "arena.actor.get_script().get_instance_id()",
        "mesh": "arena.actor.get_enemy_apparition().visual.mesh.get_instance_id()",
        "material": "arena.actor.get_enemy_apparition().visual.material_override.get_instance_id()",
    }.items():
        old_value = f'"{field}": {expression}'
        new_value = f'"{field}": {{"native_instance_id_decimal": str({expression})}}'
        assert fixture.count(old_value) == 1
        fixture = fixture.replace(old_value, new_value, 1)
    fixture = fixture.replace(
        '\treturn {"player": player, "scheduler": scheduler, "playback": playback,',
        '\t# Native object/resource IDs may exceed Exact JSON safe integers.\n'
        '\t# Decimal tags are DIAGNOSTICS ONLY; actual public packets stay exact.\n'
        '\treturn {"player": player, "scheduler": scheduler, "playback": playback,', 1)
    (directory / "source_reuse_smoke.gd").write_text(fixture)
    (directory / "run_controlled_fixture.py").write_bytes((prior / "run_controlled_fixture.py").read_bytes())

    patch = ""
    for name in ["difficulty", "authored_enemy_sequence", "replay_program", "threat_scheduler"]:
        patch += ''.join(difflib.unified_diff(
            (directory / (name + ".original.gd")).read_text().splitlines(keepends=True),
            (directory / (name + ".gd")).read_text().splitlines(keepends=True),
            fromfile="a/scripts/combat/" + name + ".gd", tofile="b/scripts/combat/" + name + ".gd"))
    (directory / "runtime-source-reuse.patch").write_text(patch)
    print("Generated new offline candidates/fixture; no live writes or engine")


if __name__ == "__main__":
    main()
