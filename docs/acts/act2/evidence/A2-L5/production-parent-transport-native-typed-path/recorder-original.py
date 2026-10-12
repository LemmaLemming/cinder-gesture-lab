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

PUBLICATION = "bd3c4458cbd1821b79c2bcda6e33f8dbaa0d5e4d"
MECHANICAL_PUBLICATION = "bd3c4458cbd1821b79c2bcda6e33f8dbaa0d5e4d"
API = "campaign-shared-41"
FIXTURE = "tests/acts/act2/a2_l5_sentry_parent_transport_smoke.gd"
PINS = {
    'scenes/acts/act2/dead_london.tscn': '1dcbdcadc4f3ccac37515a65b9f2be1b62352e6a3e735648fe441de610e76917',
    'scripts/acts/act2/dead_london.gd': 'b37799dc5139ec699a37d530faa49cad7881f8d8589bf0783e3161851e580061',
    'scripts/acts/act2/dead_london_kit.gd': '0f7d1b139c4ec9d0446f34761595dd762851e0ffe3d35e1f75cbcde63f03c983',
    'scripts/acts/act2/dead_london_sentry_visual.gd': '0d616507311b2c46dc66b9a35190088f4f95dea1712cf18ba33ed7928645e9f7',
    'scripts/acts/act2/dead_london_sentry_presented_actor.gd': '0f84ae138e572459e32575fe77e1050368c90ad4adccd1732e85496b144e5fe0',
    'scripts/acts/act2/dead_london_sentry_presented_encounter.gd': 'c72d44cb8315a70adf285ce79c25d084d439ea6c55561de42078395fe27f7517',
    FIXTURE: "0dc0544306b3bbb629ac196ef0a282d54a94c611024ba432f26dc68fb7565b2d",
    "scripts/acts/act2/dead_london_sentry_encounter.gd": "c66f9b6b25aed7f1e0b14a5f84b3cf1666bead2b40d36b14fdaf3bc011b1ea52",
    "scripts/acts/act2/dead_london_sentry_actor.gd": "ffaf6c671894715995f03fa5d2c1f54ea6b2bf720a118fb0a8b97a2269b67b5d",
    "scripts/acts/act2/dead_london_ray_exchange.gd": "d6bbcc1f35f45b4ac32226f898d924350e3b01543f28f44cf15cade7b75a3ff1",
    "scripts/acts/act2/dead_london_bait.gd": "9ae1b065521e1d521025d0f90fc941aa0f19867851ddc3eaa632432147d94808",
    "scripts/combat/lane_mechanism.gd": "873b1728019b40b229f2b7778a970cc5c8fa0001d50800cf50f2cdd50f502253",
    "scripts/combat/threat_scheduler.gd": "9b11730b4041dfb73a20e97bda0c72854a89af1ab79809fb3d8449fec624ae79",
    "scripts/combat/threat_geometry.gd": "c82501198ea1a3b53c872caec35e52604bb7256d6e71fff2c9293b430e1d8f09",
    "scripts/cues/threat_cue.gd": "c8a7abbbd4c021ec92c45e1e57fc966873110231b781dba00bd1ff3d63f5cc5a",
    "scripts/player.gd": "8e4dfeb2c285f1d786ec3268bdaf5efbc70b3b0f4b2473b2870e0566a88e4743",
    "scripts/effects.gd": "c5b8294b88e999d913a9043fd9f588a2b1f7f942280c71945a92d91d1be5b6d7",
    "scripts/equipment.gd": "2f721f0e7af0d1034ae9f92c37b4af3c3223171d0e5d2c120e42c00ae9155ab0",
    "data/design/player_equipment.json": "737cf534df88fa965ab568f750515eb17098688d268e5b6b699de5cd519b98d1",
    "tests/acts/act2/a2_l5_sentry_encounter_smoke.gd": "0b62a86763609b566809f2e0ae6e30cbe9c91b563d8e3421aff7f6ab2b9192b5",
}
SEEDS = list(PINS) + ["project.godot", "scripts/dev/dev.py", ".cinder/local.json"]
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".json", ".py", ".import"}
SUMMARY = re.compile(r"^A2-L5 native Sentry parent transport smoke: (\d+) checks, (\d+) failures;(.*)$", re.M)


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
    return {"warnings": len(re.findall(r"^WARNING:", log, re.M)), "script_errors": len(re.findall(r"^SCRIPT ERROR:", log, re.M)),
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
              "source_scope": "Explicit focused lateFoot fixture plus pinned original parent/actor/ray/bait and normal339fixture/native dependencies, Actual Shared41 bd3c4458 and strict owned1500/c1d1050c codec plus new296/0dc05443 three-owner/two-floor native transport fixture. Historical552/559 native originals remain separate immutable evidence., project/dev/local settings and recursively literal resources/UID/import sidecars. Import may scan extra resources; bounded original closure, not whole project clone.",
              "test_scope": ("New-resource parser/import only; no gameplay/native/camera/art or whole level credit." if mode == "import" else "Standard pristine/first armed Ray complete native Player+foreign Scout+B05+ONE Scheduler transport, exact two repeated quiet commits, prospective malformed atomic refusal and same-call fresh paused recipient before first physics tick; no Shell or wholelevel/art/fatal/phase2 credit.")}
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
