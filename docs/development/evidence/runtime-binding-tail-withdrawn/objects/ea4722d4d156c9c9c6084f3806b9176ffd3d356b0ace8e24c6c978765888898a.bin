"""Host-only bounded input preparation. No import/dev/Godot/Git or live writes."""
from pathlib import Path
import ast
import hashlib
import json
import os
import re
import stat

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PRODUCER = ".cinder/runtime-next-binding-tail-prepare-20261016/"
LEAF = PRODUCER + "renderer-hook-v2/authored_binding_tail_differential.gd.txt"
SELECTED = LEAF.removesuffix(".txt")
SUBJECT = "scripts/combat/authored_enemy_sequence.gd"
FIXED = {
    LEAF: "23f419e5bc17a8d868ed2d87534fa0925d0ca5cb5bf8ebc8bd4f5542701c8f7d",
    PRODUCER + "authored_enemy_sequence.candidate.gd.txt": "4b0f0db64ca52e28f7bbe8fa269b1a146b4c847570f1fb130673de4dfe97c153",
    PRODUCER + "authored_enemy_sequence.original.gd.txt": "9aed90b797bdef3388a82b63f40390e2b779f2fec671ed3914a33b1ff42950a3",
    PRODUCER + "CANDIDATE.patch": "e2a62a6257fcf856350c879ffe2f3da860ef2dd2504af09133745a45ade11cf3",
    PRODUCER + "PLAN.json": "00b42ca44a3a42de4ae70d586736dd057e6d22bf5e6ac6644313fa3703cdbbf3",
    PRODUCER + "READINESS.json": "3587456132b5e5a1b87437ac16f22588044a33f82f1ca0dacaec23b2f067d835",
    PRODUCER + "authored_binding_tail_differential.gd.txt": "5f23964b4c9ba3fa538b2bda19cc0591598f3b7c1a4cfa1f7288753dc8f3f15d",
    PRODUCER + "renderer-hook-v2/RENDERER_HOOK_FIX.patch": "4951f42c4dccd754b1f1687a36179fa9a4c79cd5ecf15afabde8697875a3549a",
    PRODUCER + "renderer-hook-v2/READINESS.json": "37292b19f555f2fea45a9e301b1199763ef57db66067fc87695a35c38dd62031",
    PRODUCER + "renderer-hook-v2/REVIEW.json": "2dc350d8f23ef058473d48ff4d8b4680b52b7b3b3c4f75854ab38eada1846d32",
    SUBJECT: "9aed90b797bdef3388a82b63f40390e2b779f2fec671ed3914a33b1ff42950a3",
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def put(name, data):
    (HERE / name).write_text(json.dumps(data, indent=2, allow_nan=False) + "\n")


def record(name):
    path = ROOT / name
    exists = os.path.lexists(path)
    status = path.lstat() if exists else None
    if exists and (not stat.S_ISREG(status.st_mode) or stat.S_ISLNK(status.st_mode)):
        raise ValueError("Named input must be regular or genuinely absent: " + name)
    return {"path": name, "sha256": sha(path) if exists else None,
            "bytes": status.st_size if status else None,
            "mode": format(stat.S_IMODE(status.st_mode), "04o") if status else None,
            "exists": exists}


def main():
    for name, digest in FIXED.items():
        if sha(ROOT / name) != digest:
            raise ValueError("Final producer/current subject drift: " + name)
    if os.path.lexists(ROOT / SELECTED) or os.path.lexists(ROOT / (SELECTED + ".uid")):
        raise ValueError("Preparation requires genuinely unselected v2 leaf and absent UID")
    cache_name = ".godot/global_script_class_cache.cfg"
    cache = (ROOT / cache_name).read_text()
    classes = {m.group(1): m.group(2) for m in re.finditer(r'"class": &"([^"]+)".*?"path": "res://([^"]+)"', cache, re.S)}
    pending, visited, edges, unresolved, egress = [LEAF], set(), [], [], []
    while pending:
        name = pending.pop(0)
        if name in visited:
            continue
        visited.add(name)
        path = ROOT / name
        if path.suffix not in [".gd", ".txt", ".tscn", ".tres"]:
            continue
        text = path.read_text()
        for target in sorted(set(re.findall(r'''res://([^"\s'\)]+)''', text))):
            if (ROOT / target).is_file():
                edges.append({"from": name, "to": target, "reason": "literal res:// reference in whole named source"})
                pending.append(target)
            else:
                unresolved.append({"from": name, "reference": target})
        for klass, target in sorted(classes.items()):
            if target != name and re.search(r"\b" + re.escape(klass) + r"\b", text):
                edges.append({"from": name, "to": target, "reason": "global class token " + klass + " resolved by pinned class cache"})
                pending.append(target)
        for line_number, line in enumerate(text.splitlines(), 1):
            if re.search(r"user://|FileAccess\.(?:open|open_compressed|open_encrypted)|DirAccess\.|HTTP(?:Request|Client)|TCPServer|StreamPeerTCP|PacketPeerUDP|WebSocketPeer|OS\.(?:execute|create_process|shell_open)", line):
                egress.append({"path": name, "line": line_number, "source": line.strip()})
    if unresolved:
        raise ValueError("Unresolved literal dependency needs explicit review: " + str(unresolved))
    project = (ROOT / "project.godot").read_text()
    if "[autoload]" in project:
        raise ValueError("Unexpected autoload needs separate bounded closure review")
    graph = {"schema_version": 1, "status": "HOST_ONLY_SOURCE_PREPARATION_UNEXECUTED", "root": LEAF,
             "selected_future_leaf": SELECTED, "resource_count": len(visited), "edge_count": len(edges),
             "resources": [record(name) for name in sorted(visited)], "edges": edges,
             "unresolved_literal_references": unresolved, "egress_review_candidates": egress,
             "method": "Recursive literal res:// references plus global-class tokens resolved from the pinned existing cache; no directory/tree/archive-bank scan or UID census.",
             "limits": "Explicit bounded source closure, not dynamic graph proof. Project main scene is bypassed by --script; no project autoload. Only named .gd UID states are observed. Engine binary/components are not copied into source CAS."}
    put("DEPENDENCY_GRAPH.json", graph)
    names = set(visited) | set(FIXED) | {"project.godot", ".cinder/local.json", cache_name, ".godot/uid_cache.bin", "scripts/dev/dev.py"}
    names |= {name + ".uid" for name in visited if name.endswith(".gd")}
    names.add(SELECTED + ".uid")
    records = [record(name) for name in sorted(names)]
    expected = {row["path"]: row["sha256"] for row in records}
    modes = {row["path"]: row["mode"] for row in records}
    expected[SELECTED], modes[SELECTED] = FIXED[LEAF], "0644"
    engine = ROOT / ".tools/Godot.app/Contents/MacOS/Godot"
    engine_expected = {"path": str(engine.resolve()), "sha256": sha(engine), "bytes": engine.stat().st_size,
                       "mode": format(stat.S_IMODE(engine.stat().st_mode), "04o")}
    own_names = ["run.py", "prepare_inputs.py", "host_tests.py", "HOST_TESTS.json", "README.md", "PROVENANCE.json", "DEPENDENCY_GRAPH.json", "INPUT_SPEC.json", "READINESS.json"]
    self_files = [str((HERE / name).relative_to(ROOT)) for name in own_names]
    put("INPUT_SPEC.json", {"schema_version": 1, "status": "READY_FOR_ROOT_SELECTION_UNEXECUTED",
                            "integration_root": str(ROOT), "root_reported_head_not_git_verified": "9f2dfa1a",
                            "accepted_api_attribution": "campaign-shared-74, Root-provided attribution; no Git invocation by preparer",
                            "subject": SUBJECT, "candidate_source": PRODUCER + "authored_enemy_sequence.candidate.gd.txt",
                            "subject_variants": {"original": {"sha256": FIXED[SUBJECT], "mode": "0644"},
                                                 "candidate": {"sha256": FIXED[PRODUCER + "authored_enemy_sequence.candidate.gd.txt"], "mode": "0644"}},
                            "inert_fixture": LEAF, "selected_fixture": SELECTED, "selected_fixture_uid_expected_absent": True,
                            "expected": expected, "expected_modes": modes, "self_files": self_files,
                            "engine_expected": engine_expected, "timeout_after_lock_seconds": 180,
                            "native_watchdog_seconds": 90, "native_report_contract": {"kind": "authored-binding-tail-differential-1", "variant_env": "CINDER_BINDING_TAIL_VARIANT", "report_env": "CINDER_BINDING_TAIL_REPORT", "semantic_projection": ["observations", "initial_wire_exact"]},
                            "scope": "Exactly one ORIGINAL and one CANDIDATE actual canonical Script correctness differential. No native execution during preparation; no acceptance or gain claim."})
    put("PROVENANCE.json", {"schema_version": 1, "status": "UNSELECTED_UNEXECUTED_SOURCE_ONLY",
                            "root_assignment": "Source-only canonical queue host. Root owns review, future exact selection/seal/execution/restore; both requests remain OPEN.",
                            "subject_observed": record(SUBJECT), "producer_pins_observed": [record(name) for name in sorted(FIXED)],
                            "host_pattern_read": record(".cinder/a2-o1-decision-host-prepare-20261016/run.py"),
                            "canonical_api_read": record("scripts/dev/dev.py"), "canonical_api_sections": "ProjectContext191+, resolve_godot259+, shared_lock_path279+, godot_lock293+, run_validation335+",
                            "leaf_preexecution_successor": "Unselected/unexecuted v1 5f239 retained. Root found null apparition without configured Playback plan; v2 23f419 uses actual renderer hook and live/signal guard. This host selects only v2 after future Root materialization.",
                            "dependency_resources": len(visited), "source_graph_edges": len(edges), "named_fixed_inputs": len(expected),
                            "selected_future_leaf_actual_at_prepare": record(SELECTED), "selected_future_uid_actual_at_prepare": record(SELECTED + ".uid"),
                            "egress_audit": {"native_writes": "Only fresh absolute CINDER_BINDING_TAIL_REPORT supplied under owned output", "catalogue_reads": "Difficulty and Equipment FileAccess.READ only", "user_store_or_network_calls_in_named_closure": False,
                                             "inherited_runtime_path_read": "tests/authored_enemy_sequence_smoke.gd _arena278-295/_world_guards298-300/_box303-318/_dispose346-350: native objects directly, no Main/Store", "default_sandbox": True,
                                             "platform_limit": "Source audit does not claim to trace all engine/platform filesystem behavior."},
                            "engine_binary": dict(engine_expected, retained_binary=False),
                            "verification": {"host_AST_parse": "Python ast.parse only", "host_tests": "7 mocked protocol/copy checks; HOST_TESTS.json", "godot_parsed": False, "engine_executed": False, "dev_imported": False, "git_invoked": False, "live_subject_written": False, "leaf_materialized": False, "seal_created": False, "Agent02_access_or_contact": False}})
    for name in ["run.py", "host_tests.py", "prepare_inputs.py"]:
        ast.parse((HERE / name).read_text(), filename=str(HERE / name))
    frozen = {str((HERE / name).relative_to(ROOT)): sha(HERE / name) for name in own_names if name != "READINESS.json"}
    put("READINESS.json", {"schema_version": 1, "status": "READY_FOR_ROOT_REVIEW_AND_FUTURE_SELECTION_UNEXECUTED",
                           "frozen_files": frozen, "fixed_input_count": len(expected), "resource_count": len(visited), "edge_count": len(edges),
                           "future_selection_needed": {"source": LEAF, "target": SELECTED, "sha256": FIXED[LEAF], "mode": "0644", "uid_absent": True},
                           "actual_native_execution": False, "actual_engine_import_or_parse": False, "actual_host_seal": False,
                           "both_requests": "OPEN; Root review/execution/decision remain separate", "host_only_tests": json.loads((HERE / "HOST_TESTS.json").read_text())})
    print(json.dumps({"resources": len(visited), "edges": len(edges), "fixed_inputs": len(expected), "status": "UNEXECUTED", "run_sha256": sha(HERE / "run.py"), "spec_sha256": sha(HERE / "INPUT_SPEC.json"), "readiness_sha256": sha(HERE / "READINESS.json")}))


if __name__ == "__main__":
    main()
