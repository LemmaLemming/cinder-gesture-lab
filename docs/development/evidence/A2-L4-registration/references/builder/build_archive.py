#!/usr/bin/env python3
"""Draft only: validate closed original receipts, then create one new portable pack.

No engine/Git calls, current-source backfill, result inference, or existing output
replacement. Original metadata and both logs are copied as separate byte streams.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import tempfile
from datetime import datetime, timezone


HERE = Path(__file__).resolve().parent
DESTINATION = "docs/development/evidence/A2-L4-registration"
OWNED = "docs/acts/act2/evidence/A2-L4"
DIAGNOSTIC = re.compile(r"SCRIPT ERROR|(?:^|\n)(?:ERROR|WARNING):|Parse Error|Compile Error|leaked|Orphan|Unclaimed", re.I)


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise ValueError(reason)


def relative(name: str) -> str:
    p = PurePosixPath(name)
    require(bool(name) and not p.is_absolute() and ".." not in p.parts, f"Unsafe path: {name}")
    return p.as_posix()


def actual(root: Path, name: str) -> Path:
    p = root / relative(name)
    require(p.is_file() and not p.is_symlink(), f"Missing/nonregular original: {name}")
    require(p.resolve().is_relative_to(root.resolve()), f"Escaped original: {name}")
    return p


def digest(p: Path) -> dict:
    h = hashlib.sha256()
    with p.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return {"bytes": p.stat().st_size, "sha256": h.hexdigest()}


def checked(root: Path, name: str, expected: dict) -> Path:
    p = actual(root, name)
    require(digest(p) == {"bytes": expected["bytes"], "sha256": expected["sha256"]}, f"Original bytes changed: {name}")
    return p


def load(root: Path, name: str) -> dict:
    value = json.loads(actual(root, name).read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"Expected JSON object: {name}")
    return value


def validate_sources(root: Path, spec: dict) -> tuple[dict, list[dict]]:
    directory = spec["prefix"] + "-source"
    manifest_name = directory + "/manifest.json"
    manifest = load(root, manifest_name)
    entries = manifest.get("files")
    require(isinstance(entries, list) and len(entries) == spec["source_count"], f"Wrong source count: {directory}")
    archive_names: set[str] = set()
    plan = []
    for entry in entries:
        require(isinstance(entry, dict), f"Malformed source entry: {directory}")
        archive = relative(entry["archived_path"])
        require(archive.startswith("files/") and archive not in archive_names, f"Repeated/escaped source member: {archive}")
        archive_names.add(archive)
        require(archive == "files/" + relative(entry["path"]), f"Source path join differs: {archive}")
        origin = directory + "/" + archive
        checked(root, origin, entry)
        plan.append({"origin": origin, "path": spec["id"] + "/source/" + archive, "bytes": entry["bytes"], "sha256": entry["sha256"], "kind": "original_source"})
    require(not manifest.get("canonical_root") or manifest["canonical_root"] == str(root), f"Original root differs: {directory}")
    physical = {p.relative_to(root / directory).as_posix() for p in (root / directory).rglob("*") if p.is_file()}
    require(physical == archive_names | {"manifest.json", ".gdignore"}, f"Archive membership differs: {directory}")
    for name in ["manifest.json", ".gdignore"]:
        origin = directory + "/" + name
        plan.append({"origin": origin, "path": spec["id"] + "/source/" + name, **digest(actual(root, origin)), "kind": "original_source_metadata"})
    return manifest, plan


def preflight(root: Path, config: dict, include_unused: bool) -> tuple[list[dict], list[dict], dict]:
    # Check every closure before touching any possibly running native/wrapper log.
    for spec in config["runs"]:
        actual(root, spec["prefix"] + "-closure.json")
    for name, expected in config["pinned_inputs"].items():
        checked(root, name, expected)

    plan: list[dict] = []
    scopes: list[dict] = []
    for spec in config["runs"]:
        prefix = spec["prefix"]
        manifest, sources = validate_sources(root, spec)
        submission = load(root, prefix + "-submission.json")
        closure = load(root, prefix + "-closure.json")
        manifest_sha = digest(actual(root, prefix + "-source/manifest.json"))["sha256"]
        require(submission.get("source_manifest_sha256") == manifest_sha == closure.get("source_manifest_sha256"), f"Submission/closure/source join differs: {prefix}")
        require(submission.get("candidate") == config["candidate"], f"Candidate differs: {prefix}")
        require(isinstance(submission.get("argv"), list) and all(type(x) is str for x in submission["argv"]), f"Missing actual argv: {prefix}")
        require(isinstance(closure.get("closed_at"), str) and bool(closure["closed_at"]), f"No observed closure: {prefix}")
        require(type(closure.get("observed_parent_exit_code")) is int, f"No observed parent exit: {prefix}")
        require(closure.get("source_count") == spec["source_count"] and closure.get("all_original_copies_exact") is True and closure.get("original_current_drift") == [], f"Original source closure not exact: {prefix}")
        checks, failures = closure.get("checks"), closure.get("failures")
        require((checks is None and failures is None) if spec["import_only"] else (type(checks) is int and type(failures) is int and 0 <= failures <= checks), f"Missing bounded results: {prefix}")
        scans = {}
        for label in ["native", "wrapper"]:
            log = closure.get("logs", {}).get(label)
            require(isinstance(log, dict), f"Missing independent {label} receipt: {prefix}")
            require(log.get("path") == prefix + "." + label + ".log", f"Unexpected original {label} path: {prefix}")
            lp = checked(root, log["path"], log)
            text = lp.read_text(encoding="utf-8", errors="replace")
            scans[label] = {"diagnostic_matches": [{"line": i, "text": line} for i, line in enumerate(text.splitlines(), 1) if DIAGNOSTIC.search(line)]}
            result_pairs = [(int(a), int(b)) for a, b in re.findall(r"(\d+) checks(?:,\s*|\s*/\s*)(\d+) failures", text)]
            scans[label]["printed_result_pairs"] = result_pairs
            # A clean closure cannot silently mask a parse/runtime diagnostic.
            if closure["observed_parent_exit_code"] == 0 and failures in [0, None]:
                require(not scans[label]["diagnostic_matches"], f"Clean closure contradicts full {label} log: {prefix}")
                if not spec["import_only"]:
                    require((checks, failures) in result_pairs, f"Clean closure lacks matching native result: {prefix}")
            plan.append({"origin": log["path"], "path": spec["id"] + "/" + label + ".log", "bytes": log["bytes"], "sha256": log["sha256"], "kind": "original_full_log"})
        plan.extend(sources)
        for ending in ["submission.json", "closure.json"]:
            origin = prefix + "-" + ending
            plan.append({"origin": origin, "path": spec["id"] + "/" + ending, **digest(actual(root, origin)), "kind": "original_receipt"})
        observed_scope = closure.get("scope") or closure.get("classification")
        require(type(observed_scope) is str and bool(observed_scope), f"Missing closure qualification: {prefix}")
        scopes.append({"id": spec["id"], "classification": "import_only" if spec["import_only"] else "clean_bounded_functional" if failures == 0 and closure["observed_parent_exit_code"] == 0 else "failed_retained", "observed_classification": closure.get("classification"), "source_count": spec["source_count"], "source_manifest_sha256": manifest_sha, "root_session": closure.get("root_session"), "observed_parent_exit_code": closure["observed_parent_exit_code"], "checks": checks, "failures": failures, "scope": observed_scope, "submission_scope": submission.get("scope"), "execution_access": submission.get("execution_access"), "actual_argv": submission["argv"], "missing_literal_references": manifest.get("missing_literal_references", []), "full_log_scan": scans})

    if include_unused:
        spec = config["unused"]
        _, sources = validate_sources(root, spec)
        qualification = load(root, spec["qualification"])
        require(qualification.get("source_manifest_sha256") == digest(actual(root, spec["prefix"] + "-source/manifest.json"))["sha256"], "Unused original qualification join differs")
        plan.extend(sources)
        scopes.append({"id": spec["id"], "classification": "unused_prequeue_freeze", "source_count": spec["source_count"], "observed_parent_exit_code": None, "checks": None, "failures": None, "scope": qualification["scope"]})

    for origin, dest in config["context_copies"].items():
        plan.append({"origin": origin, "path": dest, **digest(actual(root, origin)), "kind": "original_context_receipt"})
    # These UIDs were generated after import. Keep them outside original source sets.
    import_closure = load(root, config["runs"][0]["prefix"] + "-closure.json")
    for origin, expected in import_closure["new_uids"].items():
        p = actual(root, origin)
        require(digest(p)["sha256"] == expected["sha256"] and p.read_text().strip() == expected["id"], f"Post-import UID differs: {origin}")
        plan.append({"origin": origin, "path": "context/after-import-uids/" + origin, **digest(p), "kind": "post_import_metadata_not_original_backfill"})

    inventory = load(root, OWNED + "/files-sha256.json")
    owned_map = inventory["files_sha256"]
    require(len(owned_map) == inventory["file_count"] == config["owned_evidence_count"], "Owned inventory count differs")
    for name, sha in owned_map.items():
        require(name.startswith(OWNED + "/") and digest(actual(root, name))["sha256"] == sha, f"Authoritative owned original differs: {name}")
    physical = {p.relative_to(root).as_posix() for p in (root / OWNED).rglob("*") if p.is_file()}
    require(physical == set(owned_map) | set(inventory["excluded_inventory_metadata"]), "Authoritative owned pack membership differs")
    references = {"path": OWNED, "candidate": config["candidate"], "files_sha256": digest(actual(root, OWNED + "/files-sha256.json"))["sha256"], "indexed_artifacts": len(owned_map), "physical_members": len(physical), "all_indexed_bytes_verified": True, "copied_owned_pack": False, "scope": "Existing authoritative failed/incomplete/clean original histories remain at their own paths and original publication attribution. Root registration does not relabel or rerun them."}
    require(len({x["path"] for x in plan}) == len(plan), "Repeated output member")
    return plan, scopes, references


def build(root: Path, config: dict, include_unused: bool, check_only: bool) -> None:
    plan, scopes, references = preflight(root, config, include_unused)
    if check_only:
        print(json.dumps({"status": "preflight_only", "copy_members": len(plan), "closed_runs": len(config["runs"]), "owned_pack_copied": False}))
        return
    output = root / DESTINATION
    require(not output.exists(), f"Refuse existing output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = Path(tempfile.mkdtemp(prefix=".A2-L4-registration-", dir=output.parent))
    (temporary / ".gdignore").write_bytes(b"")
    try:
        artifacts = []
        for item in plan:
            data = checked(root, item["origin"], item).read_bytes()
            require(hashlib.sha256(data).hexdigest() == item["sha256"] and len(data) == item["bytes"], f"Original changed during copy: {item['origin']}")
            dest = temporary / relative(item["path"])
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            artifacts.append(item)
        generated = {".gdignore": b"", ".gitattributes": b"* -text\n", "README.md": (HERE / "ARCHIVE_README.md").read_bytes()}
        for name in ["build_archive.py", "expected_inputs.json", "README.md"]:
            generated["references/builder/" + name] = (HERE / name).read_bytes()
        for name, data in generated.items():
            dest = temporary / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            artifacts.append({"path": name, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(), "kind": "new_archive_metadata"})
        index = {"schema_version": 1, "created_at": datetime.now(timezone.utc).isoformat(), "status": "closed_originals_packaged_pending_independent_review", "level": "A2-L4", "candidate": config["candidate"], "shared_publication": config["shared_publication"], "runs": scopes, "authoritative_owned_evidence": references, "artifacts": sorted(artifacts, key=lambda x: x["path"]), "limits": ["No engine execution by this builder.", "Original manifests are bounded source/literal/explicit subsets, not complete native import graphs.", "After-import UIDs remain separately labeled and never enter original source manifests.", "Independent native/wrapper logs retain separate files even where bytes are identical.", "Counts and scopes remain per run; no combined acceptance, human/mobile/FPS/full-route claim."]}
        (temporary / "index.json").write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
        expected = {x["path"] for x in artifacts} | {"index.json"}
        require({p.relative_to(temporary).as_posix() for p in temporary.rglob("*") if p.is_file()} == expected, "Final output membership differs")
        for item in artifacts:
            require(digest(temporary / item["path"]) == {"bytes": item["bytes"], "sha256": item["sha256"]}, "Final copied bytes differ")
        require(not output.exists(), "Output appeared during build; refuse replacement")
        os.rename(temporary, output)
        print(json.dumps({"status": index["status"], "output": DESTINATION, "artifact_count": len(artifacts), "index": digest(output / "index.json"), "readme": digest(output / "README.md")}))
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=HERE.parent.parent)
    parser.add_argument("--omit-unused", action="store_true", help="Omit the qualified transition1 prequeue freeze; default retains it.")
    parser.add_argument("--preflight-only", action="store_true", help="Validate closed originals without creating archive output.")
    args = parser.parse_args()
    config = json.loads((HERE / "expected_inputs.json").read_text())
    build(args.root.resolve(), config, not args.omit_unused, args.preflight_only)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, json.JSONDecodeError) as error:
        raise SystemExit("Archive refused: " + str(error))
