#!/usr/bin/env python3
"""Root-run focused recorder; prepared only, never launches Godot when imported.
Usage from the assigned Act2 checkout:
  python3 /private/tmp/cinder_a2_l5_sentry_phase_string_key_record.py LABEL engine
Only dev.py owns engine admission. No import mode or source-only Godot arguments.
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
import subprocess
import sys
import threading
import time

PUBLICATION = "c6db356d2771d2b68e213a94dbcd3262e2421b3d"
MECHANICAL_PUBLICATION = "bd3c4458cbd1821b79c2bcda6e33f8dbaa0d5e4d"
API = "campaign-shared-43"
FIXTURE = "tests/acts/act2/a2_l5_sentry_phase_transport_smoke.gd"
PINS = {
    FIXTURE: "6aa89c3b316e591620bd7060519d46401936039a4ffcf3d649c2f1f83dba9f46",
    "tests/acts/act2/a2_l5_sentry_encounter_smoke.gd": "0b62a86763609b566809f2e0ae6e30cbe9c91b563d8e3421aff7f6ab2b9192b5",
    "scripts/acts/act2/dead_london_sentry_encounter.gd": "f36e42c36e32edc2e20f7fed8d2dd21b0758f356fcc7cd53332ebd93109edfc1",
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
    "scripts/campaign/exact_json.gd": "c383cbcc2391aadb4ef4c44e772ec4130038c84a7e074ea8889b56f5f08833fc",
    "scripts/campaign/snapshot_codec.gd": "36ac4a52b08020249e4282b2788f7e4bc9d1c4af7ad45fd50586e2385f6afbac",
    "data/design/player_equipment.json": "737cf534df88fa965ab568f750515eb17098688d268e5b6b699de5cd519b98d1",
}
SEEDS = list(PINS) + ["project.godot", "scripts/dev/dev.py", ".cinder/local.json"]
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".json", ".py", ".import"}
SUMMARY = re.compile(r"^A2-L5 Sentry phase transport smoke: (\d+) checks, (\d+) failures;(.*)$", re.M)
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
STARTED_JOB_LIMIT_S = 180.0  # The fixture has a 70-second native watchdog; no queue timeout.
TEST_SCOPE = ("Focused Standard/Heavy component: actual first Ray threshold and pending15HP/spent brace, "
              "public shared fatal hurt on a real pending restored tuple, natural first Foot completion, "
              "pending/delivered exactly-once phase notification, first armed phase2 pair and strict fresh quiet "
              "transport/malformed atomic refusals. TEST ONLY phase acknowledgement; no second-pool defeat, "
              "earned protected Shell checkpoint, whole route, production camera, art or balance credit.")


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


def plain(log):
    return ANSI.sub("", log)


def log_counts(log):
    log = plain(log)
    errors = re.findall(r"^\s*ERROR:.*$", log, re.M)
    assertion_errors = sum("FAIL:" in row for row in errors)
    return {"script_errors": len(re.findall(r"^\s*SCRIPT ERROR:", log, re.M)),
            "parse_or_load_errors": len(re.findall(r"^.*(?:Parse Error|Compilation failed|Failed to load script).*$", log, re.M)),
            "native_errors": len(errors), "assertion_errors": assertion_errors,
            "unexplained_native_errors": len(errors) - assertion_errors,
            "fail_markers": len(re.findall(r"FAIL:", log)),
            "warnings": len(re.findall(r"^\s*WARNING:", log, re.M))}


def class_index(root):
    # Global GDScript type references need not contain a literal res:// preload.
    result = {}
    for folder in (root / "scripts", root / "tests"):
        for path in folder.rglob("*.gd"):
            text = path.read_text(encoding="utf-8", errors="replace")
            match = re.search(r"^\s*class_name\s+([A-Za-z_]\w*)", text, re.M)
            if match:
                result.setdefault(match[1], []).append(path.relative_to(root).as_posix())
    return result


def freeze_sources(root, dest):
    pending, files, modes, uids, imports, unresolved, used_classes = list(SEEDS), {}, {}, {}, {}, set(), {}
    classes = class_index(root)
    while pending:
        name = pending.pop()
        if name in files:
            continue
        path = scoped_path(root, name)
        if not path.is_file():
            unresolved.add(name)
            continue
        content = path.read_bytes()
        files[name] = hashlib.sha256(content).hexdigest()
        native_mode = stat.S_IMODE(path.stat().st_mode)
        modes[name] = {"stat_mode": oct(native_mode), "executable_bits": native_mode & 0o111}
        out = dest / "source" / name
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(content)
        out.chmod(native_mode)
        if path.suffix in TEXT_SUFFIXES:
            text = content.decode("utf-8", errors="replace")
            pending.extend(re.findall(r'res://([^"\s\)]+)', text))
            if path.suffix == ".gd":
                for token in set(re.findall(r"\b[A-Za-z_]\w*\b", text)) & classes.keys():
                    paths = classes[token]
                    if len(paths) != 1:
                        raise ValueError("Ambiguous actual global class: " + token)
                    used_classes[token] = paths[0]
                    pending.append(paths[0])
        if path.suffix in {".gd", ".gdshader"}:
            sidecar = name + ".uid"
            uids[sidecar] = scoped_path(root, sidecar).is_file()
            if uids[sidecar]:
                pending.append(sidecar)
        if path.suffix != ".import":
            sidecar = name + ".import"
            imports[sidecar] = scoped_path(root, sidecar).is_file()
            if imports[sidecar]:
                pending.append(sidecar)
    return files, modes, uids, imports, sorted(unresolved), used_classes


def stop_owned_group(child):
    # dev.py's native child inherits this private session/process group.
    # Do not inspect, signal or delete a lock belonging to another queued job.
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
    started, termination, stream_eof = None, "", False
    try:
        with wrapper.open("x", encoding="utf-8") as stream:
            while True:
                if started is not None and time.monotonic() - started > STARTED_JOB_LIMIT_S:
                    termination = "started_engine_timeout_incomplete_scope"
                    stream.write("Recorder: bounded started engine expired; stopping only its owned process group.\n")
                    stream.flush()
                    stop_owned_group(child)
                    break
                try:
                    line = rows.get(timeout=.2)
                except queue.Empty:
                    if stream_eof and child.poll() is not None:
                        break
                    continue
                if line is None:
                    stream_eof = True
                    if child.poll() is not None:
                        break
                    continue
                stream.write(line)
                stream.flush()
                diagnostic = plain(line)
                if started is None and diagnostic.startswith("Godot Engine v"):
                    started = time.monotonic()
                if started is not None and re.match(r"^\s*SCRIPT ERROR:", diagnostic):
                    termination = "script_error_incomplete_scope"
                    stream.write("Recorder: script failure; stopping only its owned process group.\n")
                    stream.flush()
                    stop_owned_group(child)
                    break
            code = child.wait()
            thread.join(timeout=5)
            while not rows.empty():
                line = rows.get_nowait()
                if line is None:
                    stream_eof = True
                else:
                    stream.write(line)
            stream.flush()
    except BaseException:
        stop_owned_group(child)
        raise
    finally:
        if child.stdout is not None:
            child.stdout.close()
    return code, {"engine_banner_observed": started is not None, "termination": termination,
                  "queue_wait_has_no_timeout": True, "started_job_limit_s": STARTED_JOB_LIMIT_S,
                  "owned_wrapper_pid": child.pid, "child_exited": child.poll() is not None,
                  "wrapper_stream_complete": stream_eof and not thread.is_alive()}


def main():
    if len(sys.argv) != 3 or not re.fullmatch(r"[a-z0-9-]+", sys.argv[1]) or sys.argv[2] != "engine":
        raise SystemExit(__doc__)
    label = sys.argv[1]
    root = pathlib.Path.cwd().resolve()
    if subprocess.run(["git", "merge-base", "--is-ancestor", PUBLICATION, "HEAD"], cwd=root).returncode:
        raise SystemExit("Required exact published Shared43 is not adopted in this checkout")
    for name, expected in PINS.items():
        path = scoped_path(root, name)
        if not path.is_file() or digest(path) != expected:
            raise SystemExit("Original focused component source pin differs: " + name)
    for name in SEEDS:
        if not scoped_path(root, name).is_file():
            raise SystemExit("Required actual source/configuration missing: " + name)
    dest = root / "docs/acts/act2/evidence/A2-L5" / label
    raw = root / ".cinder" / ("a2-l5-" + label + ".log")
    if dest.exists() or dest.is_symlink() or raw.exists() or raw.is_symlink():
        raise SystemExit("Refuse replacing original evidence or reusing a raw-log path")
    dest.mkdir(parents=True, exist_ok=False)
    (dest / ".gdignore").write_text("", encoding="utf-8")
    files, modes, uids, imports, unresolved, used_classes = freeze_sources(root, dest)
    helper = pathlib.Path(__file__).resolve()
    shutil.copyfile(helper, dest / "recorder-original.py")
    (dest / "recorder-original.py").chmod(stat.S_IMODE(helper.stat().st_mode))
    command = ["python3", "scripts/dev/dev.py", "engine", "--path", ".", "--log-file", str(raw),
               "--headless", "--script", "res://" + FIXTURE]
    source = {"at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "cwd": str(root),
              "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
              "shared_publication": PUBLICATION, "mechanical_shared_publication": MECHANICAL_PUBLICATION,
              "api_revision": API, "command": command, "component_pins": PINS, "files": files,
              "file_modes": modes, "source_count": len(files), "uid_presence_before": uids,
              "import_sidecar_presence_before": imports, "global_class_dependencies": used_classes,
              "unresolved_literal_references": unresolved, "recorder_sha256": digest(dest / "recorder-original.py"),
              "project_modes": {"project_settings_original": "source/project.godot",
                                "local_engine_original": "source/.cinder/local.json", "native_headless": True,
                                "fixture_subviewport_declared": "540x1170 own_world_3d; UPDATE_DISABLED; no camera/pixels"},
              "source_scope": "Exact258/6aa phase fixture, clean339/0b62 native setup,1501/f36e42c3 one-line native String-key codec correction and actual pinned native APIs, project/dev/local settings; recursive literal resources, global GDScript types and UID/import sidecars. Static bounded closure includes configuration references; no whole-project source identity claim.",
              "test_scope": TEST_SCOPE, "import_requested": False}
    write_json(dest / "source.json", source)
    code, watch = run_queued(command, root, dest / "wrapper.log")
    if raw.is_file():
        shutil.copyfile(raw, dest / "raw.log")
    logs = {"wrapper": (dest / "wrapper.log").read_text(errors="replace")}
    if (dest / "raw.log").is_file():
        logs["raw"] = (dest / "raw.log").read_text(errors="replace")
    counts = {name: log_counts(log) for name, log in logs.items()}
    footers = {name: [{"checks": int(a), "failures": int(b), "scope": tail.strip()}
                      for a, b, tail in SUMMARY.findall(plain(log))] for name, log in logs.items()}
    passes = {name: len(re.findall(r"^PASS:", plain(log), re.M)) for name, log in logs.items()}
    changed = [name for name, before in files.items()
               if not scoped_path(root, name).is_file() or digest(scoped_path(root, name)) != before]
    changed_modes = [name for name, before in modes.items() if not scoped_path(root, name).is_file()
                     or oct(stat.S_IMODE(scoped_path(root, name).stat().st_mode)) != before["stat_mode"]]
    generated = {}
    for name, existed in uids.items():
        path = scoped_path(root, name)
        if not existed and path.is_file():
            mode = stat.S_IMODE(path.stat().st_mode)
            generated[name] = {"sha256": digest(path), "stat_mode": oct(mode), "executable_bits": mode & 0o111}
            out = dest / "generated-after-job" / name
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, out)
            out.chmod(mode)
    clean = code == 0 and not changed and not changed_modes and all(not any(row.values()) for row in counts.values())
    complete = (clean and "raw" in logs and watch["engine_banner_observed"] and watch["child_exited"]
                and watch["wrapper_stream_complete"] and not watch["termination"]
                and all(len(rows) == 1 and rows[0]["checks"] > 0 and rows[0]["failures"] == 0
                        and passes[name] == rows[0]["checks"] for name, rows in footers.items())
                and footers["wrapper"] == footers.get("raw"))
    chosen = logs.get("raw", logs["wrapper"])
    result = {"exit_code": code, "mode": "engine", "scope_complete": complete, "test_scope": TEST_SCOPE,
              "job_watch": watch, "log_counts": counts, "summaries": footers.get("raw", footers["wrapper"]),
              "footer_by_log": footers, "pass_line_counts": passes, "source_count": len(files),
              "sources_unchanged": not changed and not changed_modes, "changed_source_paths": changed,
              "changed_file_mode_paths": changed_modes, "uid_additions_after_job": generated,
              "source_sha256": digest(dest / "source.json"), "wrapper_sha256": digest(dest / "wrapper.log"),
              "raw_sha256": digest(dest / "raw.log") if (dest / "raw.log").is_file() else None,
              "raw_wrapper_equal": (dest / "raw.log").read_bytes() == (dest / "wrapper.log").read_bytes() if "raw" in logs else None,
              "result_lines": [row for row in plain(chosen).splitlines() if re.search(r"checks|failures|SCRIPT ERROR:|ERROR:|WARNING:|FAIL:", row)]}
    write_json(dest / "result.json", result)
    print(json.dumps({key: value for key, value in result.items() if key != "result_lines"}, sort_keys=True))
    return code if code else (0 if complete else 1)


if __name__ == "__main__":
    sys.exit(main())
