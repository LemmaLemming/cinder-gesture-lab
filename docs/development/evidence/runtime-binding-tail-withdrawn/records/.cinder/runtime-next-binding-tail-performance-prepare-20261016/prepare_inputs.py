"""Source-only bounded cost-pair specification; no dev/Godot/Git/live writes."""
from pathlib import Path
import ast
import hashlib
import json
import os
import re
import stat

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
FIXTURE = "tests/authored_echo_performance_smoke.gd"
SUBJECT = "scripts/combat/authored_enemy_sequence.gd"
PRODUCER = ".cinder/runtime-next-binding-tail-prepare-20261016/"
OLD_SPEC = ".cinder/runtime-source-projection-prepare-v2-20261016/paired-performance-prepare/INPUT_SPEC.json"
OLD_HOST = ".cinder/runtime-source-projection-prepare-v2-20261016/paired-performance-prepare/run_pair.py"
OLD_RAW = ".cinder/runtime-source-projection-prepare-v2-20261016/paired-performance-prepare/runs/pair-20261016t083903166248z-f6be20e8/original/raw.log"
PINS = {SUBJECT: "9aed90b797bdef3388a82b63f40390e2b779f2fec671ed3914a33b1ff42950a3",
        FIXTURE: "8817689cca194962b1aaa85aa950a2222ba8e56c04d1a72008e45a5e6b333ecb",
        PRODUCER + "authored_enemy_sequence.original.gd.txt": "9aed90b797bdef3388a82b63f40390e2b779f2fec671ed3914a33b1ff42950a3",
        PRODUCER + "authored_enemy_sequence.candidate.gd.txt": "4b0f0db64ca52e28f7bbe8fa269b1a146b4c847570f1fb130673de4dfe97c153",
        PRODUCER + "CANDIDATE.patch": "e2a62a6257fcf856350c879ffe2f3da860ef2dd2504af09133745a45ade11cf3"}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(name):
    path = ROOT / name
    exists = os.path.lexists(path)
    status = path.lstat() if exists else None
    if exists and (not stat.S_ISREG(status.st_mode) or stat.S_ISLNK(status.st_mode)):
        raise ValueError("Named input must be regular or genuinely absent: " + name)
    return {"path": name, "sha256": sha(path) if exists else None, "bytes": status.st_size if status else None,
            "mode": format(stat.S_IMODE(status.st_mode), "04o") if status else None, "exists": exists}


def put(name, value):
    (HERE / name).write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def main():
    old = json.loads((ROOT / OLD_SPEC).read_text())
    old_rows = old["current_original_sources"]
    if len(old_rows) != 92:
        raise ValueError("Original bounded92 cohort changed")
    for row in old_rows:
        current = record(row["path"])
        if not current["exists"] or any(current[key] != row[key] for key in ["sha256", "bytes", "mode"]):
            raise ValueError("Original113 source cohort drift; do not repin: " + row["path"])
    for name, digest in PINS.items():
        if sha(ROOT / name) != digest:
            raise ValueError("Fixed subject/fixture/donor/patch drift: " + name)
    if (ROOT / (FIXTURE + ".uid")).read_text().strip() != "uid://bxcu5vfbmmo7d":
        raise ValueError("Existing original113 fixture UID identity drift")
    if sha(HERE / "host-tests-original113.log.txt") != "f59808b5b4419d8e5ecf770d4ea6f4a0759461b82f5a284515eb9f3217ab41f6":
        raise ValueError("Historical parser-test fixture copy changed")
    cache_name = ".godot/global_script_class_cache.cfg"
    cache = (ROOT / cache_name).read_text()
    classes = {m.group(1): m.group(2) for m in re.finditer(r'"class": &"([^"]+)".*?"path": "res://([^"]+)"', cache, re.S)}
    pending, resources, edges, nonfiles = [FIXTURE], set(), [], []
    while pending:
        name = pending.pop(0)
        if name in resources:
            continue
        resources.add(name)
        path = ROOT / name
        if path.suffix not in [".gd", ".tscn", ".tres"]:
            continue
        text = path.read_text()
        for target in sorted(set(re.findall(r'''res://([^"\s'\)]+)''', text))):
            if (ROOT / target).is_file():
                edges.append({"from": name, "to": target, "reason": "whole named-source literal res:// reference"})
                pending.append(target)
            else:
                nonfiles.append({"from": name, "reference": target, "qualification": "Nonfile/output/dynamic or unused literal; not silently asserted covered"})
        for klass, target in sorted(classes.items()):
            if target != name and re.search(r"\b" + re.escape(klass) + r"\b", text):
                edges.append({"from": name, "to": target, "reason": "global class token " + klass + " resolved by pinned class cache"})
                pending.append(target)
    if "[autoload]" in (ROOT / "project.godot").read_text():
        raise ValueError("Unexpected autoload needs separate review")
    graph = {"schema_version": 1, "root": FIXTURE, "resource_count": len(resources), "edge_count": len(edges),
             "resources": [record(name) for name in sorted(resources)], "edges": edges, "nonfile_literals": nonfiles,
             "fixed_original92": {"spec": OLD_SPEC, "sha256": sha(ROOT / OLD_SPEC), "all_current_bytes_sizes_modes_equal": True, "paths": [row["path"] for row in old_rows]},
             "method": "Named existing92 plus recursive literal resource/global-class references from the unchanged fixture; UID states only for named .gd files. No directory/archive-bank scan or UID census.",
             "limits": "Bounded declared source/cohort, not dynamic/global import graph proof. Dormant base Store/screenshot methods are parsed but unexecuted by the selected113 call path."}
    put("DEPENDENCY_GRAPH.json", graph)
    names = {row["path"] for row in old_rows} | resources | set(PINS) | {OLD_SPEC, cache_name, ".godot/uid_cache.bin"}
    names |= {name + ".uid" for name in resources if name.endswith(".gd")}
    fixed = [record(name) for name in sorted(names)]
    expected = {row["path"]: row["sha256"] for row in fixed}
    modes = {row["path"]: row["mode"] for row in fixed}
    own = ["run.py", "cost_metrics.py", "prepare_inputs.py", "host_tests.py", "host-tests-original113.log.txt", "HOST_TESTS.json", "README.md", "PROVENANCE.json", "DEPENDENCY_GRAPH.json", "INPUT_SPEC.json", "READINESS.json"]
    self_files = [str((HERE / name).relative_to(ROOT)) for name in own]
    engine = ROOT / ".tools/Godot.app/Contents/MacOS/Godot"
    engine_expected = {"path": str(engine.resolve()), "sha256": sha(engine), "bytes": engine.stat().st_size, "mode": format(stat.S_IMODE(engine.stat().st_mode), "04o")}
    put("INPUT_SPEC.json", {"schema_version": 1, "status": "READY_FOR_ROOT_SELECTION_UNEXECUTED", "integration_root": str(ROOT),
                            "root_reported_head_not_git_verified": "9f2dfa1a", "accepted_api_attribution": "campaign-shared-74; Root attribution, no Git by preparer",
                            "subject": SUBJECT, "candidate_source": PRODUCER + "authored_enemy_sequence.candidate.gd.txt",
                            "subject_variants": {"original": {"sha256": PINS[SUBJECT], "mode": "0644"}, "candidate": {"sha256": PINS[PRODUCER + "authored_enemy_sequence.candidate.gd.txt"], "mode": "0644"}},
                            "selected_fixture": FIXTURE, "selected_fixture_uid": record(FIXTURE + ".uid"), "new_private_leaf": None,
                            "uid_qualification": "No new wrapper/leaf. Original fixture UID exists and must stay exact; no false absence/new allocation.",
                            "expected": expected, "expected_modes": modes, "self_files": self_files, "engine_expected": engine_expected,
                            "timeout_after_lock_seconds": 180, "native_advance_budget": 240, "cell_order": ["original", "candidate"], "maximum_cells": 2,
                            "native_workload": {"checks": 113, "automatic_advances": 72, "manual_advances": 1, "fixed_clock_probes": 15, "probe_repetitions_each": 3, "required_visuals": 1, "simulation_elapsed_s": 1.2, "world_actions": ["dash", "dash", "primary"], "primary_damage": 20},
                            "selected_metrics": {"automatic_and_each_phase": ["count", "inclusive_total_us", "mean_us", "p50_us", "p95_us", "max_us"], "manual": "same metrics, one call", "fixed_clock_each_API": "same metrics, three calls", "intervals": ["wall_elapsed_us", "admission_projection_bind_inclusive_us", "separate_fixed_clock_probe_elapsed_us"], "display_units": "preserve us and derive ms; descriptive deltas/percent only"},
                            "stopping_rule": "One ordered pair only. Functional/incomplete/source/workload mismatch stops; no fishing/replacement run. CA/warnings remain Host2 even if functional113 and API/Popen0. Root reviews all mixed/regressed metrics before any decision.",
                            "scope": "Unchanged affected113 native first-cycle measurement, actual automatic advance and fixed-clock probes. One actual canonical Authored-only original/candidate selection; no exclusive CPU/FPS/causal gain/promotion claim."})
    put("PROVENANCE.json", {"schema_version": 1, "status": "SOURCE_ONLY_UNEXECUTED", "assignment": "Root authorized this cost-pair source preparation only; full source/independent review precede execution. Both engineering requests OPEN.",
                            "original_subject": record(SUBJECT), "candidate_source": record(PRODUCER + "authored_enemy_sequence.candidate.gd.txt"), "patch": record(PRODUCER + "CANDIDATE.patch"),
                            "unchanged113_fixture": record(FIXTURE), "unchanged_fixture_uid": record(FIXTURE + ".uid"), "new_leaf_or_UID": False,
                            "prior_reviewed_host": record(OLD_HOST), "prior92_cohort_spec": record(OLD_SPEC), "all92_current_bytes_modes_equal": True,
                            "correctness_host_pattern": record(".cinder/runtime-next-binding-tail-host-prepare-20261016/run.py"),
                            "historical_host_parser_test_only": {"original": record(OLD_RAW), "private_exact_copy": record(str((HERE / "host-tests-original113.log.txt").relative_to(ROOT))), "not_this_experiment_baseline": True},
                            "dependency_counts": {"literal_global_resources": len(resources), "edges": len(edges), "fixed_inputs": len(expected)},
                            "call_path_audit": {"executed": "Performance._run/_arena/_probe_guards/_until/_finished_dash/_finish_profile; inherited _install/_lock/_response/_swipe/_tap/_ticks/_dispose/_retire/_expect plus genuine production callbacks",
                                                "not_executed": "Base playback _run/_ordinary_cycle/_capture/_fresh/restore/hostile suites; game screenshot methods and unrelated setup/process are suppressed by unchanged InputHost",
                                                "external_userdata_or_network_needed": False, "default_sandbox": True, "unchanged_bodies": True,
                                                "limit": "Dormant Store and captures declarations exist in transitive parsed sources; this is call-path audit, not a claim no such declarations exist. Engine/platform I/O is not fully traced."},
                            "engine_binary": dict(engine_expected, retained_binary=False), "host_tests": json.loads((HERE / "HOST_TESTS.json").read_text()),
                            "no_native_or_cost_result": True, "no_engine_or_import": True, "no_dev_import": True, "no_live_source_write": True, "no_Git_mail_worker_Agent02_operation": True})
    for name in ["run.py", "cost_metrics.py", "prepare_inputs.py", "host_tests.py"]:
        ast.parse((HERE / name).read_text(), filename=str(HERE / name))
    frozen = {str((HERE / name).relative_to(ROOT)): sha(HERE / name) for name in own if name != "READINESS.json"}
    put("READINESS.json", {"schema_version": 1, "status": "READY_FOR_ROOT_FULL_SOURCE_AND_INDEPENDENT_REVIEW_UNEXECUTED", "frozen_files": frozen,
                           "fixed_inputs": len(expected), "fixed_original_runtime_cohort": 92, "literal_global_resources": len(resources), "edges": len(edges),
                           "fixture_unchanged": PINS[FIXTURE], "fixture_existing_UID_preserved": "uid://bxcu5vfbmmo7d", "new_leaf_UID_expected": "Not applicable: no new wrapper/leaf created",
                           "source_AST_only": True, "host_tests": json.loads((HERE / "HOST_TESTS.json").read_text()), "engine_parsed_imported_or_executed": False, "actual_seal_created": False,
                           "requests": "Both OPEN; source readiness is not execution authorization, native credit or gain"})
    print(json.dumps({"fixed_inputs": len(expected), "resource_count": len(resources), "edges": len(edges), "nonfile_literals": nonfiles,
                      "run_sha256": sha(HERE / "run.py"), "metrics_sha256": sha(HERE / "cost_metrics.py"), "spec_sha256": sha(HERE / "INPUT_SPEC.json"), "readiness_sha256": sha(HERE / "READINESS.json"), "status": "UNEXECUTED"}))


if __name__ == "__main__":
    main()
