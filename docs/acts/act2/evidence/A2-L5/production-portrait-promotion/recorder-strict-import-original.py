#!/usr/bin/env python3
"""Root-run recorder; prepared only, not executed by its author.
From assigned checkout: python3 /private/tmp/cinder_a2_l5_production_portrait_record.py LABEL import|engine
Only dev.py launches a queued job. No source-only paths are passed to Godot.
"""
import datetime
import hashlib
import json
import os
import pathlib
import queue
import re
import shutil
import signal
import stat
import struct
import subprocess
import sys
import threading
import time

PUBLICATION = "afa6fbfdd14f8ffb917829fa7ca1a5d44ae40b79"
MECHANICAL_PUBLICATION = "bd3c4458cbd1821b79c2bcda6e33f8dbaa0d5e4d"
API = "campaign-shared-42"
FIXTURE = "tests/acts/act2/a2_l5_production_portrait_smoke.gd"
CAPTURE = "captures/act2/a2-l5-production-brief"
LABELS = ["production-entry", "direct-sentry-ray-lock", "direct-near-foot-lock", "direct-inert-coda"]
PINS = {
    FIXTURE: "7fcd2192ba89e945c7b78b8a6282868cf5cddab6bae26144a66b5e20848f8142",
    "tests/acts/act2/fixtures/a2_l5_production_art_component.tscn": "37727fd291c06753234be899276fb65f7c3bf17c5ef0c8fd7649ae1c0b81ccd1",
    "tests/acts/act2/fixtures/a2_l5_production_coda_component.tscn": "089943beeb62e2508fc843b8fdf10184878846260e82453b0a96bcfaa0d9746b",
    "scenes/acts/act2/dead_london.tscn": "1dcbdcadc4f3ccac37515a65b9f2be1b62352e6a3e735648fe441de610e76917",
    "scripts/acts/act2/dead_london.gd": "a7d9d948961183d1035f7c4af57072925c255afb94e6a0f0fad443130c40bd8e",
    "scripts/acts/act2/dead_london_sentry_encounter.gd": "c66f9b6b25aed7f1e0b14a5f84b3cf1666bead2b40d36b14fdaf3bc011b1ea52",
    "scripts/acts/act2/dead_london_sentry_presented_encounter.gd": "c72d44cb8315a70adf285ce79c25d084d439ea6c55561de42078395fe27f7517",
    "scripts/acts/act2/dead_london_sentry_presented_actor.gd": "0f84ae138e572459e32575fe77e1050368c90ad4adccd1732e85496b144e5fe0",
    "scripts/acts/act2/dead_london_sentry_visual.gd": "0d616507311b2c46dc66b9a35190088f4f95dea1712cf18ba33ed7928645e9f7",
    "scripts/acts/act2/dead_london_kit.gd": "0f7d1b139c4ec9d0446f34761595dd762851e0ffe3d35e1f75cbcde63f03c983",
    "scripts/acts/act2/dead_london_ray_exchange.gd": "d6bbcc1f35f45b4ac32226f898d924350e3b01543f28f44cf15cade7b75a3ff1",
    "scripts/acts/act2/dead_london_bait.gd": "9ae1b065521e1d521025d0f90fc941aa0f19867851ddc3eaa632432147d94808",
    "scripts/combat/lane_mechanism.gd": "873b1728019b40b229f2b7778a970cc5c8fa0001d50800cf50f2cdd50f502253",
    "scripts/combat/threat_scheduler.gd": "9b11730b4041dfb73a20e97bda0c72854a89af1ab79809fb3d8449fec624ae79",
    "scripts/combat/threat_geometry.gd": "c82501198ea1a3b53c872caec35e52604bb7256d6e71fff2c9293b430e1d8f09",
    "scripts/cues/threat_cue.gd": "c8a7abbbd4c021ec92c45e1e57fc966873110231b781dba00bd1ff3d63f5cc5a",
    "scripts/campaign/shell.gd": "8961f232a99d4d81f0c4f10d66716f7aa82fb147e3c484d6c353c78b5b46f6bc",
    "scripts/game.gd": "0b16d911409350a392f741a07bc163ad73c588d885ee7e1e64b951f97aa30d26",
    "tests/acts/act2/a2_l4_live_level_smoke.gd": "f485ead8e1dd92014969f3ae43e7fef24488f81b13d26a78208007a6f72adfba",
}
SEEDS = list(PINS) + ["project.godot", "scripts/dev/dev.py", ".cinder/local.json"]
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".json", ".py", ".import"}
SUMMARY = re.compile(r"^L5 brief production portrait smoke: (\d+) checks, (\d+) failures; scope_complete=(true|false);(.*)$", re.M)
STARTED_JOB_LIMIT_S = 900.0 # Begins at actual Godot banner, never queue wait.


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    with path.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(value, indent=2, sort_keys=True) + "\n")


def scoped_path(root, name):
    part = pathlib.PurePosixPath(name)
    if part.is_absolute() or ".." in part.parts or not name:
        raise ValueError("Unsupported relative resource: " + name)
    path = root.joinpath(*part.parts)
    if not path.resolve().is_relative_to(root):
        raise ValueError("Resource escapes assigned checkout: " + name)
    return path


def log_counts(log):
    errors = re.findall(r"^ERROR:.*$", log, re.M)
    assertion_errors = sum("FAIL:" in row for row in errors)
    return {"script_errors": len(re.findall(r"^SCRIPT ERROR:", log, re.M)), "native_errors": len(errors),
            "assertion_errors": assertion_errors, "unexplained_native_errors": len(errors) - assertion_errors,
            "fail_markers": len(re.findall(r"FAIL:", log)), "warnings": len(re.findall(r"^WARNING:", log, re.M))}


def stop_owned_group(child):
    # start_new_session makes this new wrapper/its child a private process group.
    # Never inspect/stop a lock holder or a process outside this group.
    try:
        os.killpg(child.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        child.wait(timeout=5)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        child.wait(timeout=5)


def run_queued(command, root, wrapper):
    child = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             text=True, errors="replace", bufsize=1, start_new_session=True)
    rows = queue.Queue()
    def reader():
        try:
            for line in child.stdout:
                rows.put(line)
        finally:
            rows.put(None)
    thread = threading.Thread(target=reader, daemon=True)
    thread.start()
    started, termination, output_ended = None, "", False
    try:
        with wrapper.open("x", encoding="utf-8") as stream:
            while not output_ended:
                try:
                    line = rows.get(timeout=.2)
                except queue.Empty:
                    if started is not None and time.monotonic() - started > STARTED_JOB_LIMIT_S:
                        termination = "started_engine_timeout_incomplete_scope"
                        stream.write("Recorder: bounded started engine expired; stopping only its owned process group.\n")
                        stream.flush(); stop_owned_group(child)
                        break
                    if child.poll() is not None and not thread.is_alive(): break
                    continue
                if line is None:
                    output_ended = True
                    break
                stream.write(line); stream.flush()
                if started is None and line.startswith("Godot Engine v"):
                    started = time.monotonic()
                if line.startswith("SCRIPT ERROR:"):
                    termination = "script_error_incomplete_scope"
                    stream.write("Recorder: script failure; stopping only its owned process group.\n")
                    stream.flush(); stop_owned_group(child)
                    break
            if termination:
                thread.join(timeout=2)
                while not rows.empty():
                    line = rows.get_nowait()
                    if line is not None: stream.write(line)
            code = child.wait()
    except BaseException:
        stop_owned_group(child)
        raise
    finally:
        if child.stdout is not None: child.stdout.close()
    return code, {"engine_banner_observed": started is not None, "termination": termination,
                  "queue_wait_has_no_timeout": True, "started_job_limit_s": STARTED_JOB_LIMIT_S,
                  "owned_wrapper_pid": child.pid, "child_exited": child.poll() is not None}


def archive_portraits(root, dest):
    folder = scoped_path(root, CAPTURE)
    receipt = {"expected_labels": LABELS, "images": [], "metadata": None,
               "complete": False, "problems": [], "pixel_reviewed": False, "art_accepted": False}
    if folder.exists():
        for path in sorted(folder.iterdir()):
            if path.is_file() and path.suffix in {".png", ".json"}:
                out = dest / "portraits" / path.name
                out.parent.mkdir(parents=True, exist_ok=True)
                with out.open("xb") as stream: stream.write(path.read_bytes())
    meta = folder / "metadata.exact.json"
    if not meta.is_file():
        receipt["problems"].append("No actual exact metadata written")
    else:
        receipt["metadata"] = {"original_path": CAPTURE + "/metadata.exact.json", "portable_path": "portraits/metadata.exact.json", "sha256": digest(meta)}
        try:
            data = json.loads(meta.read_text())
            if data.get("scope_complete") is not True or data.get("labels") != LABELS or [f.get("label") for f in data.get("frames", [])] != LABELS:
                receipt["problems"].append("Actual metadata does not retain exactly four completed ordered views")
            claims = data.get("claims", {})
            if not claims or any(value is not False for value in claims.values()):
                receipt["problems"].append("Unexpected full-route/earned-stage/gesture/transport/balance/art claim")
            for frame in data.get("frames", []):
                label = frame.get("label")
                if label not in LABELS:
                    receipt["problems"].append("Unknown actual image label"); continue
                path = folder / (label + ".png")
                if not path.is_file():
                    receipt["problems"].append("Missing actual image: " + label); continue
                content = path.read_bytes()
                size = list(struct.unpack(">II", content[16:24])) if content.startswith(b"\x89PNG\r\n\x1a\n") and len(content) >= 24 else None
                sha = digest(path)
                if frame.get("image_path") != "res://" + CAPTURE + "/" + label + ".png" or frame.get("image_sha256") != sha or size != [540, 1170] or frame.get("required_camera_error") != "" or frame.get("pixel_readability_accepted") is not False:
                    receipt["problems"].append("Actual image/hash/size/required-containment metadata mismatch: " + label)
                receipt["images"].append({"label": label, "original_path": CAPTURE + "/" + label + ".png", "portable_path": "portraits/" + label + ".png", "sha256": sha, "png_size": size})
        except (ValueError, TypeError, KeyError, struct.error) as error:
            receipt["problems"].append("Actual metadata/image decode refused: " + str(error))
    receipt["complete"] = not receipt["problems"] and [row["label"] for row in receipt["images"]] == LABELS
    write_json(dest / "portrait-receipt.json", receipt)
    return receipt


def main():
    if len(sys.argv) != 3 or not re.fullmatch(r"[a-z0-9-]+", sys.argv[1]) or sys.argv[2] not in {"import", "engine"}:
        raise SystemExit(__doc__)
    label, mode = sys.argv[1:]
    root = pathlib.Path.cwd().resolve()
    for name, pin in PINS.items():
        path = scoped_path(root, name)
        if not path.is_file() or digest(path) != pin: raise SystemExit("Frozen original source missing/differs: " + name)
    if subprocess.run(["git", "merge-base", "--is-ancestor", PUBLICATION, "HEAD"], cwd=root).returncode != 0:
        raise SystemExit("Root must preserve-adopt exact Shared42 before this prepared run")
    for name in SEEDS:
        if not scoped_path(root, name).is_file(): raise SystemExit("Actual source/configuration missing: " + name)
    dest = root / "docs/acts/act2/evidence/A2-L5" / label
    raw = root / ".cinder" / ("a2-l5-" + label + ".log")
    if dest.exists() or dest.is_symlink() or raw.exists() or raw.is_symlink():
        raise SystemExit("Refuse replacing original evidence or raw log")
    expected_outputs = [scoped_path(root, CAPTURE + "/" + name + ".png") for name in LABELS]
    expected_outputs.append(scoped_path(root, CAPTURE + "/metadata.exact.json"))
    if mode == "engine" and any(path.exists() or path.is_symlink() for path in expected_outputs):
        raise SystemExit("Archive/remove prior capture outputs explicitly before a new run; recorder never deletes originals")
    dest.mkdir(parents=True, exist_ok=False)
    (dest / ".gdignore").write_text("", encoding="utf-8")
    pending, seen, modes, uid_presence, unresolved = list(SEEDS), {}, {}, {}, set()
    while pending:
        name = pending.pop()
        if name in seen: continue
        path = scoped_path(root, name)
        if not path.is_file(): unresolved.add(name); continue
        content = path.read_bytes(); seen[name] = hashlib.sha256(content).hexdigest()
        bits = stat.S_IMODE(path.stat().st_mode); modes[name] = {"stat_mode": oct(bits), "executable_bits": bits & 0o111}
        out = dest / "source" / name; out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(content); out.chmod(bits)
        if path.suffix in TEXT_SUFFIXES: pending.extend(re.findall(r'res://([^"\s\)]+)', content.decode("utf-8", errors="ignore")))
        if path.suffix in {".gd", ".gdshader"}:
            sidecar = name + ".uid"; uid_presence[sidecar] = scoped_path(root, sidecar).is_file()
            if uid_presence[sidecar]: pending.append(sidecar)
        if path.suffix != ".import" and scoped_path(root, name + ".import").is_file(): pending.append(name + ".import")
    helper = pathlib.Path(__file__).resolve(); shutil.copy2(helper, dest / "recorder-original.py")
    command = ["python3", "scripts/dev/dev.py", mode]
    if mode == "engine": command += ["--path", ".", "--log-file", str(raw), "--script", "res://" + FIXTURE]
    source = {"at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "cwd": str(root),
              "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
              "shared_publication": PUBLICATION, "mechanical_shared_publication": MECHANICAL_PUBLICATION,
              "api_revision": API, "command": command, "files": seen, "file_modes": modes, "source_count": len(seen),
              "component_pins": PINS, "uid_presence_before": uid_presence, "unresolved_literal_references": sorted(unresolved),
              "recorder_sha256": digest(dest / "recorder-original.py"),
              "project_modes": {"original_project": "source/project.godot", "original_engine_local": "source/.cinder/local.json",
                                "headless": mode == "import", "native_view": "Shared Main Window/root viewport540x1170; ordinary fixed7.2 Camera/HUD; actual postdraw PNGs" if mode == "engine" else "Headless resource import only; no rendered capture"},
              "source_scope": "Fixed original437 fixture plus two TEST scenes and actual production scene/host1394 a7d9/parent1501 c66/rig/kit, native shared ordinary APIs and inherited L4 native helpers; recursively copied literal resources and existing UID/import sidecars, plus exact project/dev/local modes. Import can scan additional resources; bounded closure, not a whole project clone.",
              "test_scope": "New-resource parser/import only; no gameplay/images/art acceptance" if mode == "import" else "Brief real graphical production entry through exact packet+fresh Shell GUI Continue; actual native Sentry/Foot lock proofs on production apron/offset with collision-shortened bait; one directly constructed permanently inert corpse coda, exact four images/metadata and whole fixture cleanup. TEST supplemental closed-entry collider/coda spawn/prior prefix disclosed; no earned boss/coda, full route, balance, whole-level transport or automatic pixel acceptance."}
    write_json(dest / "source.json", source)
    code, execution = run_queued(command, root, dest / "wrapper.log")
    if raw.is_file(): shutil.copy2(raw, dest / "raw.log")
    logs = {"wrapper": (dest / "wrapper.log").read_text(errors="replace")}
    if (dest / "raw.log").is_file(): logs["raw"] = (dest / "raw.log").read_text(errors="replace")
    counts = {name: log_counts(log) for name, log in logs.items()}; chosen = logs.get("raw", logs["wrapper"])
    summaries = [{"checks": int(a), "failures": int(b), "scope_complete": c == "true", "scope": d.strip()} for a, b, c, d in SUMMARY.findall(chosen)]
    changed = [name for name, before in seen.items() if not scoped_path(root, name).is_file() or digest(scoped_path(root, name)) != before]
    changed_modes = [name for name, before in modes.items() if not scoped_path(root, name).is_file() or oct(stat.S_IMODE(scoped_path(root, name).stat().st_mode)) != before["stat_mode"]]
    generated = {}
    for name, existed in uid_presence.items():
        path = scoped_path(root, name)
        if not existed and path.is_file():
            generated[name] = digest(path); out = dest / "generated-after-job" / name
            out.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(path, out)
    receipt = archive_portraits(root, dest) if mode == "engine" else None
    clean = code == 0 and execution["child_exited"] and not execution["termination"] and not changed and not changed_modes and all(not any(row.values()) for row in counts.values())
    complete = clean if mode == "import" else clean and "raw" in logs and len(summaries) == 1 and summaries[0]["failures"] == 0 and summaries[0]["scope_complete"] and receipt["complete"]
    result = {"exit_code": code, "mode": mode, "scope_complete": complete, "execution": execution,
              "log_counts": counts, "summaries": summaries, "source_count": len(seen), "sources_unchanged": not changed and not changed_modes,
              "changed_source_paths": changed, "changed_file_mode_paths": changed_modes, "uid_additions_after_job": generated,
              "portrait_receipt_sha256": digest(dest / "portrait-receipt.json") if receipt is not None else None,
              "source_sha256": digest(dest / "source.json"), "wrapper_sha256": digest(dest / "wrapper.log"),
              "raw_sha256": digest(dest / "raw.log") if (dest / "raw.log").is_file() else None,
              "result_lines": [line for line in chosen.splitlines() if re.search(r"checks|failures|SCRIPT ERROR:|ERROR:|FAIL:", line)]}
    write_json(dest / "result.json", result)
    print(json.dumps({key: value for key, value in result.items() if key != "result_lines"}, sort_keys=True))
    return code if code else (0 if complete else 1)


if __name__ == "__main__":
    sys.exit(main())
