#!/usr/bin/env python3
"""Root-run recorder; prepared only, not executed by its author.
From assigned checkout: python3 /private/tmp/cinder_a2_l5_production_guard_record.py LABEL import|engine
Only dev.py launches a queued job. No source-only paths are passed to Godot.
"""
import datetime
import hashlib
import json
import math
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

PUBLICATION = "c6db356d2771d2b68e213a94dbcd3262e2421b3d"
MECHANICAL_PUBLICATION = "bd3c4458cbd1821b79c2bcda6e33f8dbaa0d5e4d"
API = "campaign-shared-43"
ORIGINAL_FIXTURE = "tests/acts/act2/a2_l5_production_portrait_smoke.gd"
FIXTURE = "tests/acts/act2/a2_l5_production_guard_diagnostic.gd"
DIAGNOSTIC_CAPTURE = "captures/act2/a2-l5-production-guard-diagnostic"
DIAGNOSTIC_ARTIFACT = DIAGNOSTIC_CAPTURE + "/first-refusal.exact.json"
CAPTURE = "captures/act2/a2-l5-production-brief"
LABELS = ["production-entry", "direct-sentry-ray-lock", "direct-near-foot-lock", "direct-inert-coda"]
PINS = {
    FIXTURE: "d5913a4705ebf73511cab1de5a2d9b16e9c16434638574a72caba4bf4513bcaa",
    ORIGINAL_FIXTURE: "7fcd2192ba89e945c7b78b8a6282868cf5cddab6bae26144a66b5e20848f8142",
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
EXPECTED_ASSERTIONS = (
    "bounded actual lock publication:",
    "exact four selected brief views, no partial gallery accepted",
    "actual rendered labels preserve exact scoped order",
)
PRIOR_CAPTURE_PINS = {
    "metadata.exact.json": "85b2743c6799c1a8ed3856ba45c1d2ef059c5bf71294e59b2094158170837b09",
    "production-entry.png": "89cb8eb97e50e68c9302868c6fd20e571bdfbd3b15a240334d27689be1f7be2d",
}



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
    assertion_errors = sum("FAIL:" in row or any(row.startswith("ERROR: " + prefix) for prefix in EXPECTED_ASSERTIONS) for row in errors)
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



def decode_exact_metadata(text):
    # Diagnostic metadata only: mirror the published closed exact-json-1
    # envelope/tags/bounds. Preserve float64 bits; never evaluate wire values.
    if len(text.encode("utf-8")) > 8 * 1024 * 1024:
        raise ValueError("Exact metadata exceeds supported bytes")
    containers, raw_nodes = [], 0
    in_string, escaped, in_scalar = False, False, False
    for character in text:
        if in_string:
            if escaped: escaped = False
            elif character == "\\": escaped = True
            elif character == '"': in_string = False
            continue
        if character == '"':
            in_string, in_scalar = True, False
            raw_nodes += 1
        elif character in "[{":
            containers.append(0); in_scalar = False; raw_nodes += 1
            if len(containers) > 64 * 3 + 4: raise ValueError("Exact raw depth exceeds supported bound")
        elif character in "]}":
            if containers: containers.pop()
            in_scalar = False
        elif character == ",":
            if containers:
                containers[-1] += 1
                if containers[-1] >= 16384: raise ValueError("Exact raw container exceeds supported entries")
            in_scalar = False
        elif character in ": \t\r\n": in_scalar = False
        elif not in_scalar: in_scalar = True; raw_nodes += 1
        if raw_nodes > 262144 * 5 + 16: raise ValueError("Exact raw nodes exceed supported bound")
    def object_pairs(pairs):
        result = {}
        for key, value in pairs:
            if key in result: raise ValueError("Duplicate exact envelope key")
            result[key] = value
        return result
    def reject_constant(value): raise ValueError("Unsupported nonfinite JSON constant: " + value)
    envelope = json.loads(text, object_pairs_hook=object_pairs, parse_constant=reject_constant)
    if not isinstance(envelope, dict) or set(envelope) != {"api_revision", "schema_version", "value"} or envelope["api_revision"] != "exact-json-1" or type(envelope["schema_version"]) not in (int, float) or envelope["schema_version"] != 1:
        raise ValueError("Unsupported exact metadata envelope")
    budget = [262144]
    def decode(node, depth=0):
        budget[0] -= 1
        if depth > 64 or budget[0] < 0 or not isinstance(node, list) or not node or not isinstance(node[0], str):
            raise ValueError("Invalid exact node/depth/budget")
        kind = node[0]
        if kind == "null":
            if len(node) != 1: raise ValueError("Extra exact null fields")
            return None
        if len(node) != 2: raise ValueError("Noncanonical exact tagged fields")
        value = node[1]
        if kind == "boolean" and type(value) is bool: return value
        if kind == "string" and isinstance(value, str) and "\x00" not in value: return value
        if kind == "integer":
            if not isinstance(value, str) or len(value) > (17 if value.startswith("-") else 16) or re.fullmatch(r"-?(?:0|[1-9][0-9]*)", value) is None:
                raise ValueError("Invalid exact decimal integer")
            number = int(value)
            if str(number) != value or abs(number) > 9007199254740991: raise ValueError("Noncanonical/out-of-range exact integer")
            return number
        if kind == "float64":
            if not isinstance(value, str) or re.fullmatch(r"[0-9a-f]{16}", value) is None: raise ValueError("Invalid exact lowercase float64 bytes")
            number = struct.unpack("<d", bytes.fromhex(value))[0]
            if not math.isfinite(number): raise ValueError("Nonfinite exact float64")
            return number
        if kind == "array" and isinstance(value, list) and len(value) <= 16384:
            return [decode(child, depth + 1) for child in value]
        if kind == "dictionary" and isinstance(value, list) and len(value) <= 16384:
            result = {}
            for entry in value:
                if not isinstance(entry, list) or len(entry) != 2 or not isinstance(entry[0], str) or "\x00" in entry[0] or entry[0] in result:
                    raise ValueError("Invalid/duplicate exact dictionary key")
                result[entry[0]] = decode(entry[1], depth + 1)
            return result
        raise ValueError("Unsupported exact metadata tag/type")
    decoded = decode(envelope["value"])
    if not isinstance(decoded, dict): raise ValueError("Actual view metadata requires a dictionary root")
    return decoded


def capture_members(folder):
    if folder.is_symlink() or not folder.is_dir(): raise ValueError("Only an actual capture directory can be preserved")
    files, directories = {}, {}
    for path in [folder] + sorted(folder.rglob("*")):
        if path.is_symlink(): raise ValueError("Capture symlink refused: " + str(path))
        relative = "." if path == folder else str(path.relative_to(folder))
        bits = stat.S_IMODE(path.stat().st_mode)
        if path.is_file():
            files[relative] = {"sha256": digest(path), "bytes": path.stat().st_size, "stat_mode": oct(bits)}
        elif path.is_dir(): directories[relative] = oct(bits)
        else: raise ValueError("Non-file capture member refused: " + str(path))
    return {"files": files, "directory_modes": directories}


def preserve_prior_captures(root, dest):
    # Root-authorized pre-run move only. No unlink/rmtree/delete/overwrite.
    # Move complete known roots under this packet's .gdignore, keep all bytes
    # and directory/file modes, and verify them before the new queued job.
    receipt = {"operation": "whole-directory atomic rename; no deletion", "roots": [], "verified": False}
    plans = []
    for name in [CAPTURE, DIAGNOSTIC_CAPTURE]:
        folder = scoped_path(root, name)
        if not folder.exists() and not folder.is_symlink(): continue
        before = capture_members(folder)
        if name == CAPTURE and {key: row["sha256"] for key, row in before["files"].items()} != PRIOR_CAPTURE_PINS:
            raise ValueError("Existing brief captures differ from the preserved first-failure originals; explicit new custody review required")
        target = dest / "before-run-captures" / pathlib.PurePosixPath(name).name
        if target.exists() or target.is_symlink(): raise ValueError("Prior-capture destination already exists")
        plans.append((name, folder, target, before))
    for name, folder, target, before in plans:
        target.parent.mkdir(parents=True, exist_ok=True)
        folder.rename(target)
        after = capture_members(target)
        if before != after: raise ValueError("Preserved capture bytes/modes differ after rename")
        receipt["roots"].append({"original_path": name, "portable_path": str(target.relative_to(dest)), "members": before, "after_move_identical": True})
    receipt["verified"] = True
    write_json(dest / "prior-capture-move-receipt.json", receipt)
    return receipt


def archive_portraits(root, dest):
    # Partial inherited gallery is retained, never promoted to art acceptance.
    folder = scoped_path(root, CAPTURE)
    receipt = {"expected_original_labels": LABELS, "actual_labels": [], "images": [], "metadata": None,
               "original_gallery_complete": False, "problems": [], "pixel_reviewed": False, "art_accepted": False}
    if folder.exists():
        for path in sorted(folder.iterdir()):
            if path.is_file() and path.suffix in {".png", ".json"}:
                out = dest / "portraits" / path.name
                out.parent.mkdir(parents=True, exist_ok=True)
                with out.open("xb") as stream: stream.write(path.read_bytes())
    meta = folder / "metadata.exact.json"
    if not meta.is_file():
        receipt["problems"].append("No actual inherited exact metadata written")
    else:
        receipt["metadata"] = {"original_path": CAPTURE + "/metadata.exact.json", "portable_path": "portraits/metadata.exact.json", "sha256": digest(meta)}
        try:
            data = decode_exact_metadata(meta.read_text())
            labels = data.get("labels", [])
            frames = data.get("frames", [])
            if not isinstance(labels, list) or not isinstance(frames, list) or labels != LABELS[:len(labels)] or [f.get("label") for f in frames] != labels:
                raise ValueError("Actual inherited partial labels/frames are not an original ordered prefix")
            receipt["actual_labels"] = labels
            receipt["original_gallery_complete"] = data.get("scope_complete") is True and labels == LABELS
            claims = data.get("claims", {})
            if not claims or any(value is not False for value in claims.values()):
                receipt["problems"].append("Unexpected full-route/earned-stage/gesture/transport/balance/art claim")
            for frame in frames:
                label = frame["label"]
                path = folder / (label + ".png")
                if not path.is_file():
                    receipt["problems"].append("Missing actual partial image: " + label); continue
                content = path.read_bytes()
                size = list(struct.unpack(">II", content[16:24])) if content.startswith(b"\x89PNG\r\n\x1a\n") and len(content) >= 24 else None
                sha = digest(path)
                if frame.get("image_path") != "res://" + CAPTURE + "/" + label + ".png" or frame.get("image_sha256") != sha or size != [540, 1170] or frame.get("required_camera_error") != "" or frame.get("pixel_readability_accepted") is not False:
                    receipt["problems"].append("Actual partial image/hash/size/containment metadata mismatch: " + label)
                receipt["images"].append({"label": label, "original_path": CAPTURE + "/" + label + ".png", "portable_path": "portraits/" + label + ".png", "sha256": sha, "png_size": size})
        except (ValueError, TypeError, KeyError, AttributeError, struct.error) as error:
            receipt["problems"].append("Actual inherited metadata decode refused: " + str(error))
    write_json(dest / "portrait-receipt.json", receipt)
    return receipt


def archive_diagnostic(root, dest):
    receipt = {"original_path": DIAGNOSTIC_ARTIFACT, "portable_path": "diagnostics/first-refusal.exact.json", "present": False, "complete": False, "problems": [], "art_or_gameplay_acceptance": False}
    path = scoped_path(root, DIAGNOSTIC_ARTIFACT)
    if not path.is_file():
        receipt["problems"].append("Actual first-refusal artifact missing")
    else:
        out = dest / receipt["portable_path"]
        out.parent.mkdir(parents=True, exist_ok=True)
        with out.open("xb") as stream: stream.write(path.read_bytes())
        receipt.update({"present": True, "sha256": digest(out), "bytes": out.stat().st_size})
        try:
            data = decode_exact_metadata(out.read_text())
            if data.get("api_revision") != "act2-production-guard-diagnostic-1" or data.get("original_fixture_sha256") != PINS[ORIGINAL_FIXTURE] or data.get("requested_phase") != "lock": raise ValueError("Diagnostic schema/source/requested phase differs")
            first, after = data.get("first"), data.get("after_cancel")
            if not isinstance(first, dict) or not isinstance(after, list) or first.get("first_refusal") is not True or first.get("guard_answer") is not False:
                raise ValueError("Actual first false guard record required")
            if [row.get("render_frames_after_phase_refusal") for row in after] != [0, 1, 4, 12]: raise ValueError("Exact bounded ordinary-follow observation rows required")
            for row in [first] + after:
                points = row.get("required_points")
                shifted = row.get("shifted_required_points")
                if not isinstance(points, list) or not isinstance(shifted, list) or len(points) != row.get("required_point_count") or len(shifted) != len(points): raise ValueError("Actual point count/shifted tuple mismatch")
                if not isinstance(row.get("current_error"), str) or not isinstance(row.get("settled_error"), str) or not isinstance(row.get("nodes"), list) or not isinstance(row.get("mesh_groups"), list): raise ValueError("Native containment/node diagnostics missing")
                if row.get("effective_guard_point_count") != row.get("required_point_count") + row.get("mandatory_hero_point_count"): raise ValueError("Effective original guard count differs")
                for point in points + shifted:
                    if not isinstance(point, list) or len(point) != 3 or any(type(value) not in (int, float) or not math.isfinite(value) for value in point): raise ValueError("Actual finite native required corners missing")
            write_json(dest / "diagnostics/first-refusal-decoded.json", data)
            receipt["decoded_portable_path"] = "diagnostics/first-refusal-decoded.json"
            receipt["decoded_sha256"] = digest(dest / receipt["decoded_portable_path"])
            receipt["observed_first"] = {key: first.get(key) for key in ["guard_call", "required_point_count", "effective_guard_point_count", "current_error", "settled_error", "hero_position", "camera_position", "ordinary_settled_delta", "physics_frame", "scheduler_clock_s"]}
            receipt["observed_after_cancel"] = [{key: row.get(key) for key in ["render_frames_after_phase_refusal", "current_error", "settled_error", "hero_position", "camera_position", "required_point_count"]} for row in after]
            receipt["complete"] = True
        except (ValueError, TypeError, KeyError, AttributeError) as error:
            receipt["problems"].append("Exact passive diagnostic refused: " + str(error))
    write_json(dest / "diagnostic-receipt.json", receipt)
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
        raise SystemExit("Root must preserve-adopt exact Shared43 before this prepared run")
    for name in SEEDS:
        if not scoped_path(root, name).is_file(): raise SystemExit("Actual source/configuration missing: " + name)
    dest = root / "docs/acts/act2/evidence/A2-L5" / label
    raw = root / ".cinder" / ("a2-l5-" + label + ".log")
    if dest.exists() or dest.is_symlink() or raw.exists() or raw.is_symlink():
        raise SystemExit("Refuse replacing original evidence or raw log")
    dest.mkdir(parents=True, exist_ok=False)
    (dest / ".gdignore").write_text("", encoding="utf-8")
    prior_captures = preserve_prior_captures(root, dest) if mode == "engine" else None
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
              "source_scope": "Frozen passive144 diagnostic extends unchanged original437 fixture plus two TEST scenes and actual production scene/host1394 a7d9/parent1501 c66/rig/kit, native shared ordinary APIs and inherited L4 native helpers; recursively copied literal resources and existing UID/import sidecars, plus exact project/dev/local modes. Import can scan additional resources; bounded closure, not a whole project clone.",
              "test_scope": "New passive diagnostic resource parser/import only; no native first-refusal, gameplay/images/art acceptance" if mode == "import" else "Passive first actual required presentation refusal and12 ordinary follow frames; original437 guard and all assertions unchanged. Actual construction/short completed controller dashes retained; inherited three assertion failures/raw native exit remain failed art-scope evidence, not acceptance. No camera/pose/clock/HP/input/lease writes or authority retry. Partial original gallery and actual ExactJson diagnostic retained; no Sentry/Foot/coda/full-level/art acceptance."}
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
    diagnostic = archive_diagnostic(root, dest) if mode == "engine" else None
    clean = code == 0 and execution["child_exited"] and not execution["termination"] and not changed and not changed_modes and all(not any(row.values()) for row in counts.values())
    # A completed passive observation is distinct from native/portrait success.
    # Preserve exit1 and all three original assertion failures; never report
    # the inherited failed gallery as accepted just because diagnostics exist.
    diagnostic_complete = mode == "engine" and code == 1 and execution["child_exited"] and not execution["termination"] and not changed and not changed_modes and "raw" in logs and len(summaries) == 1 and summaries[0]["failures"] == 3 and not summaries[0]["scope_complete"] and diagnostic["complete"] and not receipt["problems"] and all(row["script_errors"] == 0 and row["warnings"] == 0 and row["unexplained_native_errors"] == 0 and row["assertion_errors"] == row["native_errors"] == 3 for row in counts.values()) and all(sum(line.startswith("ERROR: " + prefix) for line in chosen.splitlines()) == 1 for prefix in EXPECTED_ASSERTIONS)
    complete = clean if mode == "import" else False
    result = {"exit_code": code, "mode": mode, "scope_complete": complete, "diagnostic_scope_complete": diagnostic_complete, "art_accepted": False, "execution": execution,
              "log_counts": counts, "summaries": summaries, "source_count": len(seen), "sources_unchanged": not changed and not changed_modes,
              "changed_source_paths": changed, "changed_file_mode_paths": changed_modes, "uid_additions_after_job": generated,
              "portrait_receipt_sha256": digest(dest / "portrait-receipt.json") if receipt is not None else None,
              "diagnostic_receipt_sha256": digest(dest / "diagnostic-receipt.json") if diagnostic is not None else None,
              "prior_capture_move_receipt_sha256": digest(dest / "prior-capture-move-receipt.json") if prior_captures is not None else None,
              "source_sha256": digest(dest / "source.json"), "wrapper_sha256": digest(dest / "wrapper.log"),
              "raw_sha256": digest(dest / "raw.log") if (dest / "raw.log").is_file() else None,
              "result_lines": [line for line in chosen.splitlines() if re.search(r"checks|failures|SCRIPT ERROR:|ERROR:|FAIL:", line)]}
    write_json(dest / "result.json", result)
    print(json.dumps({key: value for key, value in result.items() if key != "result_lines"}, sort_keys=True))
    return code if code else (0 if complete else 1)


if __name__ == "__main__":
    sys.exit(main())
