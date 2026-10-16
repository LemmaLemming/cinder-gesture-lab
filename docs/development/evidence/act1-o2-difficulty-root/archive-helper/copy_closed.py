"""Archive only explicitly confirmed CLOSED Root O2 phases; no engine or Git."""
from pathlib import Path, PurePosixPath
import argparse
import datetime
import hashlib
import json
import os
import re
import stat
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CAPSULE = HERE.parent / "verification-prepare"
PUBLIC = "docs/development/evidence/act1-o2-difficulty-root/"
FIXED = {
    "result.json", "queue.json", "raw.log", "engine.log", "command.json",
    "seal.json", "selected-seal.json", "base-source-invariant.json",
    "default-report-prefix-before-child.json", "native-report.json",
    "native-report-retention.json", "generated-native-reports.json",
    "native-observation.json", "actual-api2-receipt-inspection.json",
}
STAGES = ("preflight-observed", "sources-before-queue", "sources-at-lock",
          "sources-after-child", "sources-at-runner-close")
FIXED.update(stage + suffix for stage in STAGES for suffix in (".json", "-retention.json"))


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def strict_load(data):
    return json.loads(data, parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))


def regular(path):
    require(path.is_file() and not path.is_symlink(), "Regular original file required: " + str(path))
    return path.read_bytes()


def metadata(path):
    data = regular(path)
    return {"sha256": digest(data), "bytes": len(data), "mode_octal": format(stat.S_IMODE(path.stat().st_mode), "04o")}


def relative(name):
    p = PurePosixPath(name)
    require(isinstance(name, str) and str(p) == name and not p.is_absolute() and ".." not in p.parts and name not in ("", "."), "Safe exact relative path required")
    return name


def encoded(value):
    return (json.dumps(value, indent=2, allow_nan=False, sort_keys=True) + "\n").encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--selection", required=True, type=Path)
    parser.add_argument("--output-name")
    args = parser.parse_args()
    readiness = strict_load(regular(HERE / "READINESS.json"))
    for name, expected in readiness["frozen_files"].items():
        require(digest(regular(HERE / relative(name))) == expected, "Frozen archive helper differs: " + name)
    static = strict_load(regular(HERE / "STATIC_INPUTS.json"))
    selection_bytes = regular(args.selection.resolve())
    selected = strict_load(selection_bytes)
    require(selected.get("schema_version") == 1 and selected.get("status") == "ROOT_CONFIRMED_CLOSED_SELECTION", "An actual Root closure selection is required, never the template")
    require(isinstance(selected.get("phases"), list) and bool(selected["phases"]), "Select actual closed phases explicitly")
    require(len({row["path"] for row in selected["phases"]}) == len(selected["phases"]), "No duplicated phase")
    inputs = {}
    for name, expected in static["inputs"].items():
        path = ROOT / relative(name)
        actual = metadata(path)
        require(actual == expected, "Frozen verification capsule/promotion supplement differs: " + name)
        inputs[name] = {"bytes": regular(path), "meta": actual}
    phases = []
    # Read and verify all closed inputs before creating an output directory.
    for selection in selected["phases"]:
        phase = Path(selection["path"])
        require(phase.is_absolute() and phase.parent == CAPSULE and not phase.is_symlink() and re.fullmatch(r"run-(?:seal|parse-(?:default|registration)|default|registration)-\d{8}T\d{6}\.\d{6}Z-[0-9a-f]{8}", phase.name), "Only exact unique phase directories from this capsule are allowed")
        closure = selection.get("root_closure_confirmation")
        require(isinstance(closure, dict) and closure.get("confirmed_by") == "integration_root" and closure.get("status") == "CLOSED" and type(closure.get("runner_exit_code")) is int and isinstance(closure.get("source"), str) and bool(closure["source"]), "Explicit actual Root closure confirmation is required")
        index_bytes = regular(phase / "evidence-index.json")
        require(digest(index_bytes) == selection["evidence_index_sha256"], "Selected closed phase index changed")
        index = strict_load(index_bytes)
        require(index.get("created_after_raw_close") is True and isinstance(index.get("files"), dict), "Actual post-raw-close index required")
        members = {}
        unknown_allowed = selection.get("extra_indexed_files", {})
        require(isinstance(unknown_allowed, dict), "Explicit extra indexed file map required")
        for name, row in index["files"].items():
            relative(name)
            allowed = name in FIXED or re.fullmatch(r"source-blobs/[0-9a-f]{64}\.bin", name) or re.fullmatch(r"generated-a1-o2-difficulty-\d+-\d+\.json", name)
            if not allowed:
                require(name in unknown_allowed and unknown_allowed[name].get("sha256") == row.get("sha256") and bool(unknown_allowed[name].get("reason")), "Unreviewed indexed artifact: " + name)
            path = phase / name
            actual = metadata(path)
            require(actual["sha256"] == row.get("sha256") and actual["bytes"] == row.get("bytes"), "Closed indexed bytes differ: " + str(path))
            if name.startswith("source-blobs/"):
                require(name == "source-blobs/" + actual["sha256"] + ".bin", "Original source blob name/hash differ")
            members[name] = {"bytes": regular(path), "meta": actual}
        actual_paths = set()
        for path in phase.rglob("*"):
            require(not path.is_symlink(), "Symlink in closed phase")
            if path.is_file(): actual_paths.add(path.relative_to(phase).as_posix())
        require(actual_paths == set(members) | {"evidence-index.json"}, "Unindexed or missing actual closed artifacts; retain/review before archiving")
        require(all(name in members for name in ("result.json", "queue.json", "raw.log")), "Actual result/queue/raw originals required")
        result = strict_load(members["result.json"]["bytes"])
        require(result.get("closed") is True and type(result.get("runner_return_code")) is int and type(result.get("passed")) is bool, "Actual wrapper CLOSED status and strict recorded result required")
        require(result["runner_return_code"] == closure["runner_exit_code"], "Root closure exit and actual wrapper result differ")
        terminal = re.findall(rb"^O2 verification CLOSED code=(-?\d+)$", members["raw.log"]["bytes"], re.M)
        require(terminal == [str(result["runner_return_code"]).encode()], "Actual raw terminal closure line differs")
        source_aliases = []
        for stage in STAGES:
            observed_name, retention_name = stage + ".json", stage + "-retention.json"
            if observed_name not in members and retention_name not in members: continue
            require(observed_name in members and retention_name in members, "Original observation/retention pair incomplete")
            observed = strict_load(members[observed_name]["bytes"])
            retention = strict_load(members[retention_name]["bytes"])
            require(set(retention) == {name for name, value in observed.items() if value is not None}, "Original retention/observation alias sets differ")
            for name, row in retention.items():
                blob = row.get("blob")
                require(blob in members and blob.startswith("source-blobs/"), "Actual retained blob missing")
                actual = members[blob]["meta"]
                require(row.get("sha256") == actual["sha256"] == observed[name] and row.get("bytes") == actual["bytes"], "Original source observation/blob join differs")
                source_aliases.append({"stage": stage, "original_source_path": name, "original_retention_blob": blob, "sha256": actual["sha256"], "bytes": actual["bytes"]})
        if result["passed"]:
            require(result["runner_return_code"] == 0, "Recorded passing phase must return zero")
            if result["phase"] != "seal":
                queue = strict_load(members["queue.json"]["bytes"])
                require(result.get("engine_launch_attempted") is True and result.get("owned_validation_returned") is True and result.get("canonical_validation_return_code") == 0 and queue.get("acquired") is True and queue.get("lock_context_released") is True, "Passing engine phase must retain its actual canonical return/released lock")
            if result["phase"] == "registration":
                require("actual-api2-receipt-inspection.json" in members, "Actual native API2 receipt inspection must be retained")
        # Do not require pass, manufacture missing partial reports, or synthesize commands.
        phases.append({"path": phase, "closure": closure, "index_bytes": index_bytes, "members": members, "result": result, "source_aliases": source_aliases})
    name = args.output_name or ("pack-" + datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ") + "-" + uuid.uuid4().hex[:8])
    require(re.fullmatch(r"[a-zA-Z0-9_.-]+", name) is not None and name not in (".", ".."), "Safe unique private output name required")
    output = HERE / name
    output.mkdir(exist_ok=False)
    pack = output / "pack"
    pack.mkdir()
    files, originals, by_source_digest = {}, {}, {}
    def put(repo_path, data, mode=0o644):
        relative(repo_path)
        require(repo_path.startswith(PUBLIC), "Public path leaves the fixed evidence prefix")
        path = pack / repo_path
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.exists(): require(regular(path) == data, "Conflicting prepared destination")
        else:
            with path.open("xb") as stream: stream.write(data)
            path.chmod(mode)
        files[repo_path] = {"sha256": digest(data), "bytes": len(data), "mode_octal": format(mode, "04o")}
        return repo_path
    def retain(original, destination, data, meta):
        put(destination, data, int(meta["mode_octal"], 8))
        originals[original] = {**meta, "repository_storage_path": destination}
        return destination
    put(PUBLIC + ".gdignore", b"")
    phase_rows = []
    source_alias_count = 0
    for phase in phases:
        key = phase["path"].name
        member_map = {}
        for artifact, stored in phase["members"].items():
            data, meta = stored["bytes"], stored["meta"]
            if artifact.startswith("source-blobs/"):
                destination = PUBLIC + "source-blobs/" + meta["sha256"] + ".bin"
                by_source_digest[meta["sha256"]] = destination
            else: destination = PUBLIC + "phases/" + key + "/" + artifact
            retain(str(phase["path"] / artifact), destination, data, meta)
            member_map[artifact] = {**meta, "repository_storage_path": destination}
        index_path = PUBLIC + "phases/" + key + "/evidence-index.json"
        retain(str(phase["path"] / "evidence-index.json"), index_path, phase["index_bytes"], metadata(phase["path"] / "evidence-index.json"))
        aliases = []
        for alias in phase["source_aliases"]:
            aliases.append({**alias, "repository_storage_path": by_source_digest[alias["sha256"]]})
        source_alias_count += len(aliases)
        # Existing phase statuses/counters are copied as recorded; no new test result.
        phase_rows.append({"actual_directory_name": key, "original_absolute_directory": str(phase["path"]), "root_closure_confirmation": phase["closure"], "original_index": index_path, "recorded_result": phase["result"], "original_members": member_map, "source_observation_aliases": aliases, "actual_command_present": "command.json" in member_map, "actual_native_report_present": "native-report.json" in member_map, "actual_API2_inspection_present": "actual-api2-receipt-inspection.json" in member_map})
    for original, saved in inputs.items():
        role = static["roles"][original]
        destination = PUBLIC + "capsule-and-promotion/" + role
        retain(str(ROOT / original), destination, saved["bytes"], saved["meta"])
    for name in readiness["archive_self_files"]:
        data = regular(HERE / name)
        retain(str(HERE / name), PUBLIC + "archive-helper/" + name, data, metadata(HERE / name))
    retain(str(args.selection.resolve()), PUBLIC + "selection.original.json", selection_bytes, metadata(args.selection.resolve()))
    relocation = {"schema_version": 1, "scope": "Exact original absolute file paths/hashes/sizes/modes retained; phase source-blobs relocate to one digest CAS. Original indexes and maps remain unchanged and are not asserted to describe the new physical tree.", "files": originals}
    put(PUBLIC + "original-paths.json", encoded(relocation))
    index = {"schema_version": 1, "kind": "actual-closed-root-a1-o2-targeted-verification-archive-1", "phase_count": len(phase_rows), "phases": phase_rows, "unique_source_blobs": len(by_source_digest), "source_observation_aliases": source_alias_count, "original_path_map": PUBLIC + "original-paths.json", "scope": "Only explicitly selected actual CLOSED Root phases and exact frozen capsule/promotion. No invented parser/import/command/native pass. Host seal is not gameplay. Canonical validation return may be synthetic and retains original terminal_scope. Root independently reviews actual results before publication; packing itself is not acceptance.", "native_API2_inspection": "Only actual existing inspection files are retained; no helper-produced packet or synthetic assertion.", "other_worker_adoptions": "Not included or inferred; keep any Shared66 worker adoption evidence as a separately identified supplement.", "release_or_public_push": False}
    put(PUBLIC + "index.json", encoded(index))
    put(PUBLIC + "README.md", b"# Actual Root A1-O2 targeted verification\n\nThe index records only actual selected CLOSED phases, with their original recorded results and explicit Root closure confirmations. Exact raw/engine logs, actual commands/queue metadata, original indexes/maps/native reports/API2 receipt inspection are retained. All source-blobs are deduplicated by SHA256; original-paths.json maps every original retained file to its exact current storage. Original capsule/spec/readiness/self-review/promotion/Base provenance stays unchanged, including its historical preparation-only status.\n\nNo parser/import/command or test pass is invented. Original failures and incomplete/missing partial reports retain their scope. Host seals are not gameplay. Canonical API returns may be synthetic and are not recast as raw OS-child receipts. Packing grants no acceptance or public upload. Other worker adoption evidence remains separate.\n")
    put(PUBLIC + "COPY_REPORT.json", encoded({"schema_version": 1, "status": "EXACT_SELECTED_INPUTS_ARCHIVED_NO_NEW_NATIVE_OR_ACCEPTANCE_CREDIT", "actual_selected_phases": len(phases), "original_file_paths": len(originals), "unique_source_blobs": len(by_source_digest), "source_observation_aliases": source_alias_count, "closed_wrapper_results_as_recorded": [{"phase": row["actual_directory_name"], "passed": row["recorded_result"]["passed"], "runner_return_code": row["recorded_result"]["runner_return_code"]} for row in phase_rows], "scope": index["scope"]}))
    manifest_path = PUBLIC + "PUBLIC_COPY_MANIFEST.json"
    manifest = {"schema_version": 1, "status": "READY_FOR_ROOT_EXACT_REPOSITORY_RELATIVE_COPY_ONLY", "file_count_excluding_this_manifest": len(files), "file_count_including_this_manifest": len(files) + 1, "bytes_excluding_this_manifest": sum(row["bytes"] for row in files.values()), "self_repository_path": manifest_path, "files": dict(files), "scope": "Exact whitelist plus this manifest only, preserve modes. Files are private preparations until Root separately copies/commits them."}
    put(manifest_path, encoded(manifest))
    for name, expected in files.items():
        actual = metadata(pack / name)
        require(actual == expected, "Prepared copy verification differs: " + name)
    # Recheck original selected inputs after copy; refuse to bless drift.
    for phase in phases:
        require(regular(phase["path"] / "evidence-index.json") == phase["index_bytes"], "Original closed index changed during archive")
        for name, saved in phase["members"].items():
            require(metadata(phase["path"] / name) == saved["meta"], "Original closed member changed during archive")
    closure = {"schema_version": 1, "status": "PASS", "native_execution_by_helper": False, "new_acceptance": False, "public_files": len(files), "actual_closed_phases": len(phases), "unique_source_blobs": len(by_source_digest), "source_observation_aliases": source_alias_count, "public_manifest_sha256": files[manifest_path]["sha256"], "index_sha256": files[PUBLIC + "index.json"]["sha256"], "original_path_map_sha256": files[PUBLIC + "original-paths.json"]["sha256"], "selection_sha256": digest(selection_bytes), "scope": index["scope"]}
    (output / "PREPARATION_CLOSURE.json").write_bytes(encoded(closure))
    print(json.dumps({"private_output": str(output), **closure}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
