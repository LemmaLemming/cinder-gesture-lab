"""Bounded host-only preservation. No engine/dev import, Git or live/docs writes."""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import os
import re
import stat
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def require(value, reason):
    if not value:
        raise ValueError(reason)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read(path):
    return json.loads(path.read_text())


def relative(value):
    require(type(value) is str and value and not Path(value).is_absolute() and ".." not in Path(value).parts, "Unsafe relative path")
    return value


def local(value):
    return ROOT / relative(value)


def observation(path):
    info = path.lstat()
    require(stat.S_ISREG(info.st_mode) and not stat.S_ISLNK(info.st_mode), "Only exact regular original files may be copied: " + str(path))
    data = path.read_bytes()
    return {"sha256": sha(data), "bytes": len(data), "mode": format(stat.S_IMODE(info.st_mode), "04o")}, data


def save(path, value):
    with path.open("xb") as stream:
        stream.write((json.dumps(value, indent=2, allow_nan=False) + "\n").encode())


def collect(spec):
    originals, phase_reports = {}, []
    def add(path, role, expected=None):
        name = str(path.relative_to(ROOT))
        row, _ = observation(path)
        if expected:
            require(all(row[key] == expected[key] for key in expected if key in row), "Original hash/size/mode mismatch: " + name)
        if name not in originals:
            originals[name] = dict(row, original_path=name, roles=[])
        require(all(originals[name][key] == row[key] for key in row), "Original changed during inventory: " + name)
        if role not in originals[name]["roles"]:
            originals[name]["roles"].append(role)
    def phase(entry):
        base = local(entry["path"])
        index = base / "evidence-index.json"
        require(sha(index.read_bytes()) == entry["index_sha256"], "Explicit closed index pin differs: " + str(index))
        result = read(base / "result.json")
        require(result.get("closed") is True, "Only actual closed phases are archival evidence")
        nested = [index]
        seen = set()
        while nested:
            selected = nested.pop()
            if selected in seen:
                continue
            seen.add(selected)
            meta = read(selected)
            require(meta.get("created_after_raw_close") is True and type(meta.get("files")) is dict, "Original closed index schema required")
            add(selected, entry["role"])
            for name, expected in meta["files"].items():
                path = selected.parent / relative(name)
                add(path, entry["role"], expected)
                if path.name == "evidence-index.json":
                    nested.append(path)
        phase_reports.append({"role": entry["role"], "path": entry["path"], "index_sha256": entry["index_sha256"],
                              "nested_index_count": len(seen), "original_result_path": str((base / "result.json").relative_to(ROOT)),
                              "closed": result["closed"], "passed": result.get("passed"), "runner_return_code": result.get("runner_return_code"),
                              "result_unchanged": True})
    for entry in spec["closed_phases"]:
        phase(entry)
    if spec.get("actual_cost_pair"):
        phase(spec["actual_cost_pair"])
    for group in spec["frozen_control_groups"]:
        readiness = local(group["readiness"])
        require(sha(readiness.read_bytes()) == group["sha256"], "Frozen control readiness differs")
        add(readiness, group["role"])
        for name, digest in read(readiness)["frozen_files"].items():
            add(local(name), group["role"], {"sha256": digest, "mode": "0644"})
    for entry in spec["explicit_original_files"]:
        add(local(entry["path"]), entry["role"], {key: entry[key] for key in ["sha256", "bytes", "mode"] if key in entry})
    return originals, phase_reports


def summary(originals):
    cas = {row["sha256"]: row["bytes"] for name, row in originals.items() if "source-blobs" in Path(name).parts}
    plain = [row for name, row in originals.items() if "source-blobs" not in Path(name).parts]
    return {"original_files": len(originals), "original_bytes": sum(row["bytes"] for row in originals.values()),
            "original_CAS_aliases": sum("source-blobs" in Path(name).parts for name in originals), "unique_CAS_objects": len(cas),
            "projected_payload_files": len(plain) + len(cas), "projected_payload_bytes": sum(row["bytes"] for row in plain) + sum(cas.values()),
            "scope": "Whitelisted originals only; excludes generated manifests/README and engine binary"}


def build(spec, originals, phases, spec_path):
    require(spec.get("actual_cost_pair") is not None and spec.get("final_readme") is not None and spec.get("status") == "READY_FOR_PRIVATE_PACK_REVIEW",
            "Actual closed cost pair, selected seal/reviews and final private archive README still required; no final pack produced")
    readme = local(spec["final_readme"]["path"])
    require(readme.is_relative_to(HERE) and sha(readme.read_bytes()) == spec["final_readme"]["sha256"], "Final private README pin differs")
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / ("pack-" + stamp + "-" + uuid.uuid4().hex[:8])
    pack = out / "pack" / relative(spec["portable_destination"])
    pack.mkdir(parents=True, exist_ok=False)
    relocations, stored = [], {}
    for name, row in sorted(originals.items()):
        source = local(name)
        before, data = observation(source)
        require(all(before[key] == row[key] for key in before), "Original changed before copy: " + name)
        is_cas = "source-blobs" in Path(name).parts
        if is_cas:
            require(re.fullmatch(r"[0-9a-f]{64}\.bin", source.name) and source.stem == row["sha256"], "CAS filename/full bytes do not join")
            destination = "objects/" + row["sha256"] + ".bin"
            storage_mode = "0644"
        else:
            destination = "records/" + name
            if source.suffix == ".gd":
                destination += ".txt"  # Inert relocation, no source-byte rewrite.
            storage_mode = row["mode"]
        target = pack / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        if destination not in stored:
            with target.open("xb") as stream:
                stream.write(data)
            os.chmod(target, int(storage_mode, 8))
            stored[destination] = dict(observation(target)[0], portable_path=destination)
        require(stored[destination]["sha256"] == row["sha256"] and stored[destination]["bytes"] == row["bytes"] and stored[destination]["mode"] == storage_mode, "Portable byte object/mode mismatch")
        relocations.append(dict(row, original_absolute_path=str(source), portable_path=destination,
                                storage_mode=storage_mode, original_mode_recoverable=True, source_bytes_reserialized=False,
                                storage="deduplicated_source_CAS" if is_cas else "verbatim_original"))
    (pack / "README.md").write_bytes(readme.read_bytes())
    os.chmod(pack / "README.md", 0o644)
    save(pack / "RELOCATION.json", {"schema_version": 1, "original_full_file_hashes_and_modes": True, "rows": relocations,
                                    "qualification": "Original source maps/index JSON stay unchanged. CAS aliases resolve here; modes refer to each original and separately to storage. Historical context outside the whitelist is not silently fetched."})
    save(pack / "PACK_PROVENANCE.json", {"schema_version": 1, "spec_original": str(spec_path), "spec_sha256": sha(spec_path.read_bytes()),
                                         "summary": summary(originals), "closed_phase_original_facts": phases,
                                         "gain_promotion_acceptance_decision": False, "engine_executed": False, "original_evidence_rewritten": False})
    save(pack / "index.json", {"schema_version": 1, "status": "ROOT_WITHDRAWN_CANDIDATE_ORIGINAL_EVIDENCE_PRESERVED",
                               "readme": "README.md", "manifest": "PACK_MANIFEST.json", "relocation_manifest": "RELOCATION.json",
                               "root_decision": spec["root_decision"], "closed_phase_facts": phases, "summary": summary(originals),
                               "preservation_only": True, "engine_executed_by_packer": False, "new_native_visual_or_acceptance_credit": False})
    for name, row in originals.items():
        final, _ = observation(local(name))
        require(all(final[key] == row[key] for key in final), "Original changed during pack: " + name)
    for row in stored.values():
        current, _ = observation(pack / row["portable_path"])
        require(all(current[key] == row[key] for key in current), "Portable stored object drift")
    files = []
    for path in sorted(pack.rglob("*")):
        if path.is_file():
            row, _ = observation(path)
            files.append(dict(row, path=str(path.relative_to(pack))))
    save(pack / "PACK_MANIFEST.json", {"schema_version": 1, "files": files,
                                       "self_manifest_excluded": True, "original_alias_count": len(relocations), "all_verbatim_originals_and_stored_objects_verified": True})
    publication = [str(path.relative_to(out / "pack")) for path in sorted(pack.rglob("*")) if path.is_file()]
    (out / "PUBLICATION_PATHS.txt").write_text("\n".join(publication) + "\n")
    (out / "PUBLICATION_PATHS.nul").write_bytes(b"\0".join(name.encode() for name in publication) + b"\0")
    save(out / "PREPARATION_CLOSURE.json", {"status": "PRIVATE_PRESERVATION_PACK_PREPARED_NOT_PUBLISHED", "pack": str(pack),
                                           "manifest_sha256": sha((pack / "PACK_MANIFEST.json").read_bytes()), "files": len(publication),
                                           "originals_unchanged": True, "engine_Git_live_docs_or_upload_operation": False,
                                           "gain_promotion_acceptance_decision": False})
    print(str(out))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["inventory", "build"])
    parser.add_argument("--spec", type=Path, default=HERE / "PACK_SPEC.json")
    args = parser.parse_args()
    spec_path = args.spec.resolve()
    require(spec_path.is_relative_to(HERE), "Private explicit pack specification required")
    spec = read(spec_path)
    originals, phases = collect(spec)
    if args.mode == "inventory":
        out = HERE / ("INVENTORY-" + datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ") + ".json")
        save(out, {"status": "PENDING_COST_ACTUAL_PRIVATE_PREPARATION_ONLY" if not spec.get("actual_cost_pair") else "PRIVATE_ORIGINAL_INVENTORY",
                   "summary": summary(originals), "originals": list(originals.values()), "closed_phases": phases,
                   "actual_cost_pair": spec.get("actual_cost_pair"), "final_pack_created": False, "engine_Git_live_docs_or_upload_operation": False})
        print(json.dumps({"path": str(out), "summary": summary(originals), "cost_actual_pending": spec.get("actual_cost_pair") is None}))
    else:
        build(spec, originals, phases, spec_path)


if __name__ == "__main__":
    main()
