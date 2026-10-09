#!/usr/bin/env python3
"""Root-run recorder for the actual B05 parent mechanics fixture; no source-only CLI args.
Usage from the assigned checkout: python3 /private/tmp/cinder_a2_l5_parent_record.py LABEL import|engine
This draft is not invoked by its author. Native jobs go solely through dev.py.
"""
import datetime
import hashlib
import json
import pathlib
import re
import shutil
import stat
import subprocess
import sys

PUBLICATION = "a400355ffa551eba0c50bdc12bf9f36518d3a30b"
MECHANICAL_PUBLICATION = "9ef31ace408aa9a4ed4a7409351773beb3dca34d"
API = "campaign-shared-39"
FIXTURE = "tests/acts/act2/a2_l5_sentry_encounter_smoke.gd"
PINS = {
    FIXTURE: "0b62a86763609b566809f2e0ae6e30cbe9c91b563d8e3421aff7f6ab2b9192b5",
    "scripts/acts/act2/dead_london_sentry_encounter.gd": "d89967446d5786189cae1371a06934256fa901d6c2042bbc9dff6d10195ce26d",
    "scripts/acts/act2/dead_london_ray_exchange.gd": "d6bbcc1f35f45b4ac32226f898d924350e3b01543f28f44cf15cade7b75a3ff1",
    "scripts/acts/act2/dead_london_sentry_actor.gd": "ffaf6c671894715995f03fa5d2c1f54ea6b2bf720a118fb0a8b97a2269b67b5d",
    "scripts/acts/act2/dead_london_bait.gd": "9ae1b065521e1d521025d0f90fc941aa0f19867851ddc3eaa632432147d94808",
    "scripts/cues/threat_cue.gd": "c8a7abbbd4c021ec92c45e1e57fc966873110231b781dba00bd1ff3d63f5cc5a",
}
SEEDS = list(PINS) + ["project.godot", "scripts/dev/dev.py", ".cinder/local.json"]
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".json", ".py", ".import"}
SUMMARY = re.compile(r"^A2-L5 native Sentry parent mechanics smoke: (\d+) checks, (\d+) failures;(.*)$", re.M)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    with path.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(value, indent=2, sort_keys=True) + "\n")


def scoped_path(root, name):
    part = pathlib.PurePosixPath(name)
    if part.is_absolute() or ".." in part.parts or not name:
        raise ValueError("Unsupported resource path: " + name)
    path = root.joinpath(*part.parts)
    if not path.resolve().is_relative_to(root):
        raise ValueError("Resource escapes checkout: " + name)
    return path


def log_counts(log):
    errors = re.findall(r"^ERROR:.*$", log, re.M)
    assertions = [row for row in errors if "FAIL:" in row]
    return {"script_errors": len(re.findall(r"^SCRIPT ERROR:", log, re.M)),
            "native_errors": len(errors), "assertion_errors": len(assertions),
            "unexplained_native_errors": len(errors) - len(assertions),
            "fail_markers": len(re.findall(r"FAIL:", log))}


def main():
    if len(sys.argv) != 3 or not re.fullmatch(r"[a-z0-9-]+", sys.argv[1]) or sys.argv[2] not in {"import", "engine"}:
        raise SystemExit(__doc__)
    label, mode = sys.argv[1:]
    root = pathlib.Path.cwd().resolve()
    for name, expected in PINS.items():
        path = scoped_path(root, name)
        if not path.is_file() or digest(path) != expected:
            raise SystemExit("Original component/publication source pin differs: " + name)
    for name in SEEDS:
        if not scoped_path(root, name).is_file():
            raise SystemExit("Required actual source/configuration missing: " + name)
    dest = root / "docs/acts/act2/evidence/A2-L5" / label
    raw = root / ".cinder" / ("a2-l5-" + label + ".log")
    if dest.exists() or dest.is_symlink() or raw.exists() or raw.is_symlink():
        raise SystemExit("Refuse replacing an original evidence bundle or reusing a raw-log path")
    dest.mkdir(parents=True, exist_ok=False)
    (dest / ".gdignore").write_text("", encoding="utf-8")
    queue, seen, uid_presence, file_modes = list(SEEDS), {}, {}, {}
    unresolved = set()
    while queue:
        name = queue.pop()
        if name in seen:
            continue
        path = scoped_path(root, name)
        if not path.is_file():
            # Comments/project registries can mention optional assets; report
            # these references rather than claiming they were captured.
            unresolved.add(name)
            continue
        content = path.read_bytes()
        seen[name] = hashlib.sha256(content).hexdigest()
        native_mode = stat.S_IMODE(path.stat().st_mode)
        file_modes[name] = {"stat_mode": oct(native_mode), "executable_bits": native_mode & 0o111}
        out = dest / "source" / name
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(content)
        out.chmod(native_mode)
        if path.suffix in TEXT_SUFFIXES:
            for dependency in re.findall(r'res://([^"\s\)]+)', content.decode("utf-8", errors="ignore")):
                queue.append(dependency)
        if path.suffix in {".gd", ".gdshader"}:
            sidecar = name + ".uid"
            uid_presence[sidecar] = scoped_path(root, sidecar).is_file()
            if uid_presence[sidecar]:
                queue.append(sidecar)
        sidecar = name + ".import"
        if path.suffix != ".import" and scoped_path(root, sidecar).is_file():
            queue.append(sidecar)
    helper = pathlib.Path(__file__).resolve()
    shutil.copyfile(helper, dest / "recorder-original.py")
    (dest / "recorder-original.py").chmod(stat.S_IMODE(helper.stat().st_mode))
    command = ["python3", "scripts/dev/dev.py", mode]
    if mode == "engine":
        command += ["--path", ".", "--log-file", str(raw), "--headless", "--script", "res://" + FIXTURE]
    source = {"at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "cwd": str(root), "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
              "shared_publication": PUBLICATION, "mechanical_shared_publication": MECHANICAL_PUBLICATION, "api_revision": API, "command": command,
              "files": seen, "file_modes": file_modes, "source_count": len(seen), "component_pins": PINS,
              "uid_presence_before": uid_presence, "unresolved_literal_references": sorted(unresolved),
              "recorder_sha256": digest(dest / "recorder-original.py"),
              "project_modes": {"project_settings_original": "source/project.godot", "local_engine_original": "source/.cinder/local.json",
                                "native_headless": True, "fixture_subviewport_declared": "540x1170 own_world_3d; UPDATE_DISABLED; no camera/pixel evidence"},
              "source_scope": "Explicit original parent mechanics fixture, actual finite two-pool parent/two persistent native Ray+Foot owners, shared39 mechanical Ray/actor/bait/Cue and adopted metadata supplement, project/dev/local settings, recursively captured literal resources and existing UID/import sidecars. Import may scan additional project resources; this is not a complete project clone.",
              "test_scope": ("New-resource parser/import only. No fixture gameplay execution, parent/controller/combat/whole B05/level/checkpoint/save, portrait/art, base/Longstep, effects-policy transport or performance credit." if mode == "import" else "Actual native finite two-pool B05 mechanics parent on a flat20x20 dry fixture floor, canonical Heavy under Standard and Assisted budget1, distinct persistent Ray+Foot owners/one encounter epoch/one composite cue, actual canceled Ray and completed Foot receipts, stable phase eligibility/test-only host acknowledgment, proof-directed actual paired escape/return/full current primary cadence/late refusal/public primary defeat and permanent cleanup. Native admitted proof credits neither blast nor invulnerability; physical execution must produce no exposure opportunity. No exact theoretical-to-actual full-path replay identity or portable checkpoint/save/Continue/Retry/Fatal/Attempts provenance, whole Game/level/effects-policy transport, physical joint base/Longstep kit, recognizer/screen aiming, actual portrait/camera/art, human balance, performance or mobile/export/release acceptance.")}
    write_json(dest / "source.json", source)
    with (dest / "wrapper.log").open("x", encoding="utf-8") as stream:
        finished = subprocess.run(command, cwd=root, stdout=stream, stderr=subprocess.STDOUT)
    if raw.is_file():
        shutil.copyfile(raw, dest / "raw.log")
    logs = {"wrapper": (dest / "wrapper.log").read_text(errors="replace")}
    if (dest / "raw.log").is_file():
        logs["raw"] = (dest / "raw.log").read_text(errors="replace")
    counts = {name: log_counts(log) for name, log in logs.items()}
    chosen = logs.get("raw", logs["wrapper"])
    summaries = [{"checks": int(m[0]), "failures": int(m[1]), "scope": m[2].strip()}
                 for m in SUMMARY.findall(chosen)]
    changed = [name for name, before in seen.items()
               if not scoped_path(root, name).is_file() or digest(scoped_path(root, name)) != before]
    changed_modes = [name for name, before in file_modes.items() if not scoped_path(root, name).is_file() or oct(stat.S_IMODE(scoped_path(root, name).stat().st_mode)) != before["stat_mode"]]
    generated_uids = {}
    for name, existed in uid_presence.items():
        path = scoped_path(root, name)
        if not existed and path.is_file():
            generated_uids[name] = digest(path)
            out = dest / "generated-after-job" / name
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, out)
    clean = finished.returncode == 0 and not changed and not changed_modes and all(not any(row.values()) for row in counts.values())
    complete = clean if mode == "import" else clean and "raw" in logs and len(summaries) == 1 and summaries[0]["failures"] == 0
    result = {"exit_code": finished.returncode, "mode": mode, "scope_complete": complete,
              "log_counts": counts, "summaries": summaries, "source_count": len(seen),
              "sources_unchanged": not changed and not changed_modes, "changed_source_paths": changed, "changed_file_mode_paths": changed_modes,
              "uid_additions_after_job": generated_uids,
              "source_sha256": digest(dest / "source.json"), "wrapper_sha256": digest(dest / "wrapper.log"),
              "raw_sha256": digest(dest / "raw.log") if (dest / "raw.log").is_file() else None,
              "raw_wrapper_equal": (dest / "raw.log").read_bytes() == (dest / "wrapper.log").read_bytes() if (dest / "raw.log").is_file() else None,
              "pass_line_counts": {name: len(re.findall(r"^PASS:", log, re.M)) for name, log in logs.items()},
              "result_lines": [row for row in chosen.splitlines() if re.search(r"checks|failures|SCRIPT ERROR:|ERROR:|FAIL:", row)]}
    write_json(dest / "result.json", result)
    print(json.dumps({key: value for key, value in result.items() if key != "result_lines"}, sort_keys=True))
    return finished.returncode if finished.returncode else (0 if complete else 1)


if __name__ == "__main__":
    sys.exit(main())
