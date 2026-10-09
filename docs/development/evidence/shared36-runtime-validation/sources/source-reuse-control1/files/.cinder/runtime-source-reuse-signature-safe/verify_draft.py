#!/usr/bin/env python3
"""Static byte/signature/AST verification only; never runs GDScript or jobs."""
from pathlib import Path
import ast
import hashlib
import json
import re


def digest(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def methods(text: str) -> dict[str, tuple[str, str]]:
    lines = text.splitlines(keepends=True)
    result = {}
    for index, line in enumerate(lines):
        match = re.match(r"^(?:static )?func (\w+)\(", line)
        if not match:
            continue
        end = index + 1
        while end < len(lines) and (not lines[end].strip() or lines[end].startswith("\t")):
            end += 1
        result[match.group(1)] = (line.rstrip(), ''.join(lines[index:end]).rstrip() + '\n')
    return result


def main() -> None:
    directory = Path(__file__).resolve().parent
    root = directory.parent.parent
    frozen = json.loads((directory / "frozen-inputs-before.json").read_text())
    for name, receipt in {**frozen["live"], **frozen["prior_frozen"]}.items():
        data = (root / name).read_bytes()
        assert len(data) == receipt["bytes"] and digest(data) == receipt["sha256"], name

    changed = {}
    same_counts = {}
    originals = {}
    candidates = {}
    allowed = {
        "difficulty": {"_init"},
        "authored_enemy_sequence": {"_resolve"},
        "replay_program": set(),
        "threat_scheduler": {"authored_replay_source_error"},
    }
    for stem, permitted in allowed.items():
        original = (directory / (stem + ".original.gd")).read_text()
        candidate = (directory / (stem + ".gd")).read_text()
        originals[stem] = methods(original)
        candidates[stem] = methods(candidate)
        assert set(originals[stem]) <= set(candidates[stem])
        actual_changed = []
        for name, (signature, body) in originals[stem].items():
            current_signature, current_body = candidates[stem][name]
            assert signature == current_signature, f"Signature changed: {stem}.{name}"
            if body != current_body:
                actual_changed.append(name)
        assert set(actual_changed) == permitted, (stem, actual_changed)
        changed[stem] = sorted(actual_changed)
        same_counts[stem] = len(originals[stem]) - len(actual_changed)

    # All Authored public/virtual paths remain exactly the guarded0939 bodies.
    assert "_snapshot_error_with_inputs" not in candidates["authored_enemy_sequence"]
    source_factory = candidates["authored_enemy_sequence"]["_restore_for_source_guard"][1]
    assert source_factory.index("get_script() != CinderAuthoredEnemySequence") < source_factory.index("_source_guard_inputs = validation_inputs")
    assert source_factory.index("_source_guard_inputs = validation_inputs") < source_factory.index("var restored: bool = restore_state") < source_factory.index("_source_guard_inputs = null") < source_factory.index("if not restored:")
    assert len(re.findall(r"^\s+return\b", source_factory, re.MULTILINE)) == 3

    scheduler_before = (directory / "threat_scheduler.original.gd").read_text()
    scheduler_after = (directory / "threat_scheduler.gd").read_text()
    original_body = originals["threat_scheduler"]["authored_replay_source_error"][1]
    current_body = candidates["threat_scheduler"]["authored_replay_source_error"][1]
    assert scheduler_before.replace(original_body, "<source-error>\n", 1) == scheduler_after.replace(current_body, "<source-error>\n", 1)
    prefix = current_body[:current_body.index('\tvar plan: Dictionary = reader.state()')]
    assert prefix == original_body[:original_body.index('\tvar plan: Dictionary = reader.state()')].replace("reader.restore_state(", "reader._restore_authored_for_source_guard(")
    native_span_start = '\tvar plan: Dictionary = reader.state()'
    native_span_end = '\tvar world: Dictionary = '
    assert current_body[current_body.index(native_span_start):current_body.index(native_span_end)] == original_body[original_body.index(native_span_start):original_body.index(native_span_end)]
    guards = ["request_attack", "_request_attack", "_prepare_ordinary_attack", "_commit_ordinary_attack", "request_tracking", "request_lunge", "preview_lunge", "preview_stationary", "_cycle_fresh_owner_error"]
    guard_receipts = {name: digest(originals["threat_scheduler"][name][1].encode()) for name in guards}
    constant = next(line for line in scheduler_before.splitlines() if line.startswith("const MANAGED_ORDINARY_ERROR:"))
    assert constant in scheduler_after.splitlines()
    fixture = (directory / "source_reuse_smoke.gd").read_text()
    assert fixture.count('"native_instance_id_decimal": str(') == 4
    assert 'if before.is_empty(): return' in fixture
    assert 'not after.is_empty() and _callbacks.is_empty() and after == before' in fixture
    assert 'source_instance": arena.actor.get_instance_id()' not in fixture
    assert 'func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:' in fixture
    assert 'func _input_error(sequence_id: Variant, definition: Dictionary, source_id: Variant, source_epoch: String, generation: int, profile_id: Variant, world: Dictionary) -> String:' in fixture
    for name in ["build_draft.py", "verify_draft.py", "run_controlled_fixture.py"]:
        ast.parse((directory / name).read_text(), filename=name)
    report = {
        "scope": "Static exact-byte/function/signature/AST checks only; no GDScript parse/native execution",
        "changed_original_function_bodies": changed,
        "unchanged_original_function_counts": same_counts,
        "all_original_signatures_and_arities_exact": True,
        "guarded0939_public_validator_and_comparison_bodies_exact": True,
        "exact_native_factory_before_collection": True,
        "sink_detached_success_and_failure_before_source_hook": True,
        "all_scheduler_bytes_outside_source_error_exact": True,
        "native_source_and_world_boundary_span_exact": True,
        "managed_owner_guard_function_sha256": guard_receipts,
        "managed_error_constant_exact": constant,
        "diagnostic_native_id_tags": 4,
        "nonempty_before_and_after_exact_receipts_required": True,
        "unchanged_frozen_prior_files": len(frozen["prior_frozen"]),
        "unchanged_live_inputs": len(frozen["live"]),
        "python_AST_checks_only": ["build_draft.py", "verify_draft.py", "run_controlled_fixture.py"],
    }
    (directory / "static-verification.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
