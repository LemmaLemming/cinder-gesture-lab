#!/usr/bin/env python3
"""Root-run focused recorder; prepared only, never launches Godot when imported.
Usage from the assigned Act2 checkout:
  python3 /private/tmp/cinder_a2_l5_act3_transition_interface_boundary_record.py LABEL engine
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
FIXTURE = "tests/acts/act2/a2_l5_act3_transition_interface_smoke.gd"
PINS = {
    "data/campaign/act3/a3_l1_encounters.json": "e6aec8f14077b036f621578a16fd0ed1a1c92d95d9184d4b2bfdc4f9164598f6",
    "data/campaign/registry.json": "95e7fbcd91067d823f962495c421cb6eb7447f5641db21f1defda4922e04953c",
    "data/design/player_equipment.json": "737cf534df88fa965ab568f750515eb17098688d268e5b6b699de5cd519b98d1",
    "scenes/acts/act2/dead_london.tscn": "1dcbdcadc4f3ccac37515a65b9f2be1b62352e6a3e735648fe441de610e76917",
    "scenes/acts/act3/a3_l1.tscn": "149fc50072900d64c5c03f372ec0c4471ac189d23a98a72ebd3bab6b6597a84c",
    "scenes/main.tscn": "c0c169890eed0afb26b1a09a017d45c90a64aa8ba874a683deb141c4190ee06b",
    "scenes/player.tscn": "68cf79442eb217cb0e2afcc4099080ba79c3f3b2c548655195d0864f4fc8bfac",
    "scripts/acts/act2/dead_london.gd": "a7d9d948961183d1035f7c4af57072925c255afb94e6a0f0fad443130c40bd8e",
    "scripts/acts/act2/dead_london_bait.gd": "9ae1b065521e1d521025d0f90fc941aa0f19867851ddc3eaa632432147d94808",
    "scripts/acts/act2/dead_london_kit.gd": "0f7d1b139c4ec9d0446f34761595dd762851e0ffe3d35e1f75cbcde63f03c983",
    "scripts/acts/act2/dead_london_sentry_actor.gd": "ffaf6c671894715995f03fa5d2c1f54ea6b2bf720a118fb0a8b97a2269b67b5d",
    "scripts/acts/act2/dead_london_sentry_encounter.gd": "f36e42c36e32edc2e20f7fed8d2dd21b0758f356fcc7cd53332ebd93109edfc1",
    "scripts/acts/act2/dead_london_sentry_presented_actor.gd": "0f84ae138e572459e32575fe77e1050368c90ad4adccd1732e85496b144e5fe0",
    "scripts/acts/act2/dead_london_sentry_presented_encounter.gd": "c72d44cb8315a70adf285ce79c25d084d439ea6c55561de42078395fe27f7517",
    "scripts/acts/act2/dead_london_sentry_visual.gd": "0d616507311b2c46dc66b9a35190088f4f95dea1712cf18ba33ed7928645e9f7",
    "scripts/acts/act2/ray_scout_exchange.gd": "6d8e11a29254cad18947655d8e7470d7892b18e856e534859ae6211a897ae7e2",
    "scripts/acts/act3/sunbound_stalker.gd": "a59eb53e322e2b8cffa4314e21c716721c1a11c6cd6c1333f7c9b6f0650551a7",
    "scripts/acts/act3/twin_suns.gd": "ec1392ab0c287e4e099c43bedd9c217f56705e747c8db18c5cd749220e77b897",
    "scripts/acts/act3/twin_suns_level.gd": "17ae090ea809c3170aef76e8393b0b2edde9f85b719dff2b7e55edfca9499247",
    "scripts/campaign/attempts.gd": "6701abec6181beb3934490e468b00868c14e69eb229f708d562b98efe32a43a0",
    "scripts/campaign/exact_json.gd": "c383cbcc2391aadb4ef4c44e772ec4130038c84a7e074ea8889b56f5f08833fc",
    "scripts/campaign/level.gd": "1989a4170b68329afd6f49c5698b23aa96722883698ccacf32f905619539010d",
    "scripts/campaign/registry.gd": "2b29babb103d121d8f4d185b0d56cb094e9693f099a10731ac6363ead9ee4fe2",
    "scripts/campaign/save_store.gd": "5b6974a1ea23f6fe0fe852f42c99310e28380caa182eea47491ef1180214aed0",
    "scripts/campaign/shell.gd": "8961f232a99d4d81f0c4f10d66716f7aa82fb147e3c484d6c353c78b5b46f6bc",
    "scripts/campaign/snapshot_codec.gd": "36ac4a52b08020249e4282b2788f7e4bc9d1c4af7ad45fd50586e2385f6afbac",
    "scripts/combat/lane_mechanism.gd": "873b1728019b40b229f2b7778a970cc5c8fa0001d50800cf50f2cdd50f502253",
    "scripts/combat/threat_geometry.gd": "c82501198ea1a3b53c872caec35e52604bb7256d6e71fff2c9293b430e1d8f09",
    "scripts/combat/threat_scheduler.gd": "9b11730b4041dfb73a20e97bda0c72854a89af1ab79809fb3d8449fec624ae79",
    "scripts/dev/dev.py": "28afb59c142488b8f80e1c93072ea790d674aa12868988602b5c55e096a03192",
    "scripts/effects.gd": "c5b8294b88e999d913a9043fd9f588a2b1f7f942280c71945a92d91d1be5b6d7",
    "scripts/equipment.gd": "2f721f0e7af0d1034ae9f92c37b4af3c3223171d0e5d2c120e42c00ae9155ab0",
    "scripts/game.gd": "0b16d911409350a392f741a07bc163ad73c588d885ee7e1e64b951f97aa30d26",
    "scripts/player.gd": "8e4dfeb2c285f1d786ec3268bdaf5efbc70b3b0f4b2473b2870e0566a88e4743",
    "scripts/ui/campaign_menu.gd": "33781eb8150da96a9eed0e194cadff146f1b9712831c742195f539943dfeff28",
    "tests/acts/act2/a2_l5_act3_transition_interface_smoke.gd": "0195030546858c2038518905374d4b8b52e233f13aee4b19ac7c6c0e45e849fb",
    "tests/acts/act2/a2_l5_loading_retry_smoke.gd": "e5e53402b7c4d8a288d56824fdc3810b67ea5a5f00cbf53cb76425d3bdbc0b19",
    "tests/acts/act2/fixtures/a2_l5_production_coda_component.tscn": "089943beeb62e2508fc843b8fdf10184878846260e82453b0a96bcfaa0d9746b"
}
SEEDS = list(PINS) + ["project.godot", "scripts/dev/dev.py", ".cinder/local.json"]
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".json", ".py", ".import"}
SUMMARY = re.compile(r"^A2-L5 Act3 transition interface smoke: (\d+) checks, (\d+) failures;(.*)$", re.M)
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
STARTED_JOB_LIMIT_S = 180.0  # The fixture has an 80-second native watchdog; no queue timeout.
TEST_SCOPE = 'Source-proven TEST-only one paused process_frame contact boundary plus passive original field/error reporting; unchanged focused real Shell/Attempts/public actual completion and measured production-region contact IDs through an explicitly TEST CinderLevel with actual unentered coda geometry; unchanged canonical A3-L1 fresh five-source recipient, exact actual carried gear/HP/ammo/partial reload/aim/menu consumption, durable predecessor+recipient, fresh disk Continue and cleanup. Separate strict pristine production L5 entrance codec; preceding completion prefix is unearned TEST metadata. No strict production terminal/local26 coda dispatch, earned boss/checkpoint/route, A3 combat, full recognizer, portrait/art/balance/performance credit.'


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
    assertion_errors = sum("FAIL L5 loading:" in row for row in errors)
    return {"script_errors": len(re.findall(r"^\s*SCRIPT ERROR:", log, re.M)),
            "parse_or_load_errors": len(re.findall(r"^.*(?:Parse Error|Compilation failed|Failed to load script).*$", log, re.M)),
            "native_errors": len(errors), "assertion_errors": assertion_errors,
            "unexplained_native_errors": len(errors) - assertion_errors,
            "fail_markers": len(re.findall(r"FAIL L5 loading:", log)),
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
            raise SystemExit("Original focused transition source pin differs: " + name)
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
                                "fixture_viewport_declared": "540x1170 root window; inherited paused fresh constructor uses own World3D; no pixel acceptance"},
              "source_scope": "Original374/9f8 transition fixture plus one actual paused process_frame, strict Pause-drain/menu check, exactly two passive calls and one field/error reporter, clean352/e5 initial production constructor helper,1501/f36 actual codec and canonical destination, pinned native APIs, project/dev/local settings; recursive literal resources, global GDScript types and UID/import sidecars. Static bounded closure includes configuration references; no whole-project source identity claim.",
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
                        and passes[name] == 0 for name, rows in footers.items())
                and footers["wrapper"] == footers.get("raw"))
    chosen = logs.get("raw", logs["wrapper"])
    result = {"exit_code": code, "mode": "engine", "scope_complete": complete, "test_scope": TEST_SCOPE,
              "job_watch": watch, "log_counts": counts, "summaries": footers.get("raw", footers["wrapper"]),
              "footer_by_log": footers, "pass_line_counts": passes, "source_count": len(files),
              "sources_unchanged": not changed and not changed_modes, "changed_source_paths": changed,
              "changed_file_mode_paths": changed_modes, "uid_additions_after_job": generated,
              "assertion_reporting": "inherited count-only _expect; exactly zero PASS lines; full positive footer and zero diagnostics required",
              "source_sha256": digest(dest / "source.json"), "wrapper_sha256": digest(dest / "wrapper.log"),
              "raw_sha256": digest(dest / "raw.log") if (dest / "raw.log").is_file() else None,
              "raw_wrapper_equal": (dest / "raw.log").read_bytes() == (dest / "wrapper.log").read_bytes() if "raw" in logs else None,
              "result_lines": [row for row in plain(chosen).splitlines() if re.search(r"checks|failures|SCRIPT ERROR:|ERROR:|WARNING:|FAIL:", row)]}
    write_json(dest / "result.json", result)
    print(json.dumps({key: value for key, value in result.items() if key != "result_lines"}, sort_keys=True))
    return code if code else (0 if complete else 1)


if __name__ == "__main__":
    sys.exit(main())
