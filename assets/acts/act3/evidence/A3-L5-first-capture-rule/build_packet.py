"""Package only explicitly closed Crystalman originals; no active source reads."""
from pathlib import Path
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[2]
DEST = Path(__file__).resolve().parent
RUNS = [
    ("crystalman-rule-import-native", "closed_import"),
    ("crystalman-rule-first-native", "closed_parse_failure"),
    ("crystalman-rule-await-corrected-native", "unexecuted_preparation"),
    ("crystalman-rule-await-corrected-v2-native", "closed_assertion_failure"),
    ("crystalman-rule-landing-diagnostic-native", "closed_readonly_diagnostic_failure"),
    ("crystalman-rule-completion-observed-native", "unexecuted_preparation_missing_wrapper"),
    ("crystalman-rule-completion-observed-v2-native", "closed_focused_pass"),
]
CUSTODY = [
    "a3-l5-capture-rule-publication",
    "a3-l5-rule-await-fix",
    "a3-l5-rule-landing-diagnostic",
    "a3-l5-rule-completion-observation-fix",
]
BASELINE = "ffdf26e0c77bb0a5a33e52aadcf45f1610a56a3f"
OWNED_HEAD = "54f6db70766679317a930e53864751d794b437a2"
RUNTIME_PATH = "scripts/acts/act3/crystalman_rule_room.gd"
DRIVER_PATH = "tests/acts/act3/crystalman_rule_room_smoke.gd"
SCENE_PATH = "scenes/acts/act3/a3_l5_crystalman_rule_room.tscn"
RUNTIME_SHA = "94451c6f29115d0cbb93c5da022d73dc8d60cf58d764d6dbea06db9bb6640644"
SCENE_SHA = "a2226de053911045502a4fe3d98fce76f0135bcdf6c9f87cab8c24ee17d88374"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_json(path):
    return json.loads(path.read_text())


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


def copy_exact(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    before = source.read_bytes()
    if destination.exists():
        assert destination.read_bytes() == before, str(destination)
    else:
        shutil.copy2(source, destination)
    assert source.read_bytes() == before and destination.read_bytes() == before
    return {"original_path": str(source.relative_to(ROOT)),
            "packet_path": str(destination.relative_to(DEST)),
            "bytes": len(before), "sha256": digest(before)}


def main():
    blobs = {}
    originals = []
    runs = []
    reference_count = 0
    for name, classification in RUNS:
        origin = ROOT / ".cinder" / name
        target = DEST / "runs" / name
        freeze = read_json(origin / "source-freeze.json")
        assert freeze["baseline"] == BASELINE
        assert freeze["api_revision"] == "campaign-shared-52"
        assert freeze["owned_head"] == OWNED_HEAD
        assert freeze["sources"][RUNTIME_PATH] == RUNTIME_SHA
        assert freeze["sources"][SCENE_PATH] == SCENE_SHA
        frozen_paths = {str(p.relative_to(origin / "sources"))
                        for p in (origin / "sources").rglob("*") if p.is_file()}
        assert frozen_paths == set(freeze["sources"]), name
        mapping = []
        for logical_path, expected_hash in sorted(freeze["sources"].items()):
            source = origin / "sources" / logical_path
            data = source.read_bytes()
            assert digest(data) == expected_hash, (name, logical_path)
            if expected_hash not in blobs:
                destination = DEST / "source-blobs" / expected_hash / source.name
                copy_exact(source, destination)
                blobs[expected_hash] = {
                    "packet_path": str(destination.relative_to(DEST)),
                    "bytes": len(data), "sha256": expected_hash,
                }
            blob = blobs[expected_hash]
            assert (DEST / blob["packet_path"]).read_bytes() == data
            mapping.append({"original_logical_path": logical_path,
                            "original_frozen_path": str(source.relative_to(ROOT)),
                            **blob})
        write_json(target / "source-map.json", {
            "schema_version": 1,
            "original_manifest": "source-freeze.json",
            "scope": "Same bytes; deduplicated storage only. Logical paths retained.",
            "source_count": len(mapping), "sources": mapping,
        })
        reference_count += len(mapping)
        for source in sorted(origin.iterdir()):
            if source.is_file():
                originals.append(copy_exact(source, target / source.name))
        result_path = origin / "result.json"
        result = read_json(result_path) if result_path.exists() else None
        footer = None
        raw_log_hash = None
        pass_lines = None
        if (origin / "native.log").exists():
            log = (origin / "native.log").read_text()
            raw_log_hash = digest((origin / "native.log").read_bytes())
            assert result and result["raw_log_sha256"] == raw_log_hash
            pass_lines = len(re.findall(r"^PASS:", log, re.M))
            matches = re.findall(r"Crystalman first one-slot rule room: (\d+) checks; failures: (\d+); actual post-actor ticks: (\d+)\.", log)
            if matches:
                assert len(matches) == 1
                checks, failures, ticks = map(int, matches[0])
                assert pass_lines == checks - failures
                footer = {"checks": checks, "failures": failures, "actual_post_actor_ticks": ticks}
            assert result.get("original_source_changes", result.get("original_frozen_sources_changed", [])) == []
        if classification.startswith("unexecuted"):
            assert result is None and not (origin / "native.log").exists(), name
        if name == "crystalman-rule-completion-observed-native":
            assert len(mapping) == 529 and "scripts/dev/dev.py" not in freeze["sources"]
        if name == "crystalman-rule-completion-observed-v2-native":
            assert result["exit_code"] == 0 and result["diagnostics"] == []
            assert footer == {"checks": 55, "failures": 0, "actual_post_actor_ticks": 655}
        run = {
            "name": name, "classification": classification,
            "original_directory": str(origin.relative_to(ROOT)),
            "manifest_path": str((target / "source-freeze.json").relative_to(DEST)),
            "source_map_path": str((target / "source-map.json").relative_to(DEST)),
            "source_count": len(mapping), "baseline": freeze["baseline"],
            "api_revision": freeze["api_revision"], "owned_head": freeze["owned_head"],
            "created_at_original": freeze["created_at"],
            "exit_code": result["exit_code"] if result else None,
            "command": result["command"] if result else None,
            "raw_log_sha256": raw_log_hash, "footer": footer,
            "pass_lines": pass_lines,
            "driver_sha256": freeze["sources"][DRIVER_PATH],
            "runtime_sha256": RUNTIME_SHA, "scene_sha256": SCENE_SHA,
        }
        write_json(target / "observation.json", run)
        runs.append(run)
    for name in CUSTODY:
        origin = ROOT / ".cinder" / name
        target = DEST / "custody" / name
        for source in sorted(origin.iterdir()):
            if source.is_file():
                originals.append(copy_exact(source, target / source.name))
    for name, receipt_name in [("a3-l5-rule-await-fix", "custody.json"),
                               ("a3-l5-rule-landing-diagnostic", "custody.json"),
                               ("a3-l5-rule-completion-observation-fix", "receipt.json")]:
        p = DEST / "custody" / name
        receipt = read_json(p / receipt_name)
        assert digest((p / "before.gd.txt").read_bytes()) == receipt["before_sha256"]
        assert digest((p / "after.gd.txt").read_bytes()) == receipt["after_sha256"]
    write_json(DEST / "diagnosis.json", {
        "scope": "Derived reading of the preserved diagnostic; original native log remains exact.",
        "original_diagnostic": "runs/crystalman-rule-landing-diagnostic-native/native.log",
        "classification": "test observed nominal witness end while actual response dash was still live",
        "observed_operands": {
            "actual_hp": 100.0, "original_hp": 100.0,
            "actual_position": [0, -0.0048437617, 2.5],
            "expected_position": [0, -0.0048437617, 2.7],
            "distance_error": 0.20000005,
            "dash_left_s": 0.013333333333333384,
            "velocity": [0, 0, 15], "latest_record_kind": "primary",
            "latest_record_sequence": 2,
            "player_clock_s": 2.499999999999996,
            "scheduler_clock_s": 2.499999999999996,
            "nominal_segment_end_s": 2.4966666666666644,
        },
        "fix_scope": "Observe actual completed dash/publication within original witness deadline, without cooldown wait or runtime/geometry/HP/tolerance retune.",
        "final_result": "55 checks/0 failures/655 actual post-actor ticks; clean exit0;530 frozen inputs unchanged.",
        "open_limit": "Actual full primary recovery deadline not independently asserted yet.",
    })
    write_json(DEST / "original-custody.json", {
        "schema_version": 1, "original_files": originals,
        "bytes_of_originals_rewritten": False,
        "raw_source_freezes_preserved": True,
        "source_reference_count": reference_count,
        "unique_source_blob_count": len(blobs),
    })
    artifacts = []
    for path in sorted(DEST.rglob("*")):
        if path.is_file() and path.name != "index.json":
            data = path.read_bytes()
            artifacts.append({"path": str(path.relative_to(DEST)),
                              "bytes": len(data), "sha256": digest(data)})
    index = {
        "schema_version": 1, "level_id": "A3-L5",
        "scope": "First one-slot component original evidence only; ignored draft packet, not owned publication.",
        "baseline": BASELINE, "api_revision": "campaign-shared-52", "owned_head": OWNED_HEAD,
        "runs": runs, "source_reference_count": reference_count,
        "unique_source_blob_count": len(blobs),
        "original_non_source_file_count": len(originals),
        "artifact_count_excluding_index": len(artifacts),
        "physical_file_count_including_index": len(artifacts) + 1,
        "limitations": ["No whole-parent Save/Continue/Retry or canonical campaign history",
                        "No phase2/full-level/coda/art or actual graphical portrait fidelity",
                        "Full primary recovery deadline not independently asserted",
                        "No full-route/human balance/desktop frame cost/mobile claim",
                        "Import528 scope is relevant literal/ClassName closure, not complete prequeue import graph"],
        "artifacts": artifacts,
    }
    write_json(DEST / "index.json", index)
    print(json.dumps({"status": "READY", "index_sha256": digest((DEST / "index.json").read_bytes()),
                      "source_references": reference_count, "unique_source_blobs": len(blobs),
                      "physical_files": len(artifacts) + 1, "original_non_source_files": len(originals)}, indent=2))


if __name__ == "__main__":
    main()
