#!/usr/bin/env python3
"""Root-run recorder; prepared only, not executed by its author.
From assigned checkout: python3 /private/tmp/cinder_a2_l5_production_proof_diagnostic_record.py LABEL import|engine
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
FIXTURE = "tests/acts/act2/a2_l5_production_proof_diagnostic.gd"
OBSERVER = "tests/acts/act2/fixtures/a2_l5_tracking_commit_observer.gd"
ORIGINAL_FIXTURE = "tests/acts/act2/a2_l5_production_portrait_smoke.gd"
DIAGNOSTIC_ARTIFACT = "captures/act2/a2-l5-production-proof-diagnostic/actual-commits.exact.json"
GENERIC_PROOF_EXHAUSTION = "No supported collision/floor-safe timed escape and ordinary-primary opening through the committed threat union"
EXPECTED_ASSERTIONS = ["bounded actual lock publication:", "exact four selected brief views, no partial gallery accepted", "actual rendered labels preserve exact scoped order"]
CAPTURE = "captures/act2/a2-l5-production-brief"
LABELS = ["production-entry", "direct-sentry-ray-lock", "direct-near-foot-lock", "direct-inert-coda"]
PINS = {
    FIXTURE: "34a44f1923c091de8f736cd143182d0b28f516593aec79f5c5feb9a6c53680b9",
    OBSERVER: "5d2fc9238fd3ba83cf6a3ac73402f5eec9f145be292f8d5c6d6103475a0b4160",
    ORIGINAL_FIXTURE: "642faf7bce97ea3a7c52d584a2cedf97f89d3a43fd700ecefc04eb711c720a7a",
    "tests/acts/act2/fixtures/a2_l5_production_art_component.tscn": "37727fd291c06753234be899276fb65f7c3bf17c5ef0c8fd7649ae1c0b81ccd1",
    "tests/acts/act2/fixtures/a2_l5_production_coda_component.tscn": "089943beeb62e2508fc843b8fdf10184878846260e82453b0a96bcfaa0d9746b",
    "scenes/acts/act2/dead_london.tscn": "1dcbdcadc4f3ccac37515a65b9f2be1b62352e6a3e735648fe441de610e76917",
    "scripts/acts/act2/dead_london.gd": "a7d9d948961183d1035f7c4af57072925c255afb94e6a0f0fad443130c40bd8e",
    "scripts/acts/act2/dead_london_sentry_encounter.gd": "f36e42c36e32edc2e20f7fed8d2dd21b0758f356fcc7cd53332ebd93109edfc1",
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
PRIOR_CAPTURE_PINS = {"captures/act2/a2-l5-production-brief": {"metadata.exact.json": "9c00ba08b9b38007d18fef521a1637cc695877385bf88b2478081568aa5741d3", "production-entry.png": "4bcfd7dbe122ba212602ca4285df482c0a86351b0689ad5449e691a573aff0fa"}, "captures/act2/a2-l5-production-proof-diagnostic": {}}
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".json", ".py", ".import"}
SUMMARY = re.compile(r"^L5 brief production portrait smoke: (\d+) checks, (\d+) failures; scope_complete=(true|false);(.*)$", re.M)
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
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


def plain(log):
    return ANSI.sub("", log)


def log_counts(log):
    log = plain(log)
    errors = re.findall(r"^\s*ERROR:.*$", log, re.M)
    owned = sum(any(row.lstrip().startswith("ERROR: " + prefix) for prefix in EXPECTED_ASSERTIONS) for row in errors)
    return {"script_errors": len(re.findall(r"^\s*SCRIPT ERROR:", log, re.M)),
            "parse_or_load_errors": len(re.findall(r"^.*(?:Parse Error|Compilation failed|Failed to load script).*$", log, re.M)),
            "native_errors": len(errors), "assertion_errors": owned,
            "unexplained_native_errors": len(errors) - owned,
            "fail_markers": len(re.findall(r"FAIL:", log)), "warnings": len(re.findall(r"^\s*WARNING:", log, re.M))}


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
    for name, expected in PRIOR_CAPTURE_PINS.items():
        folder = scoped_path(root, name)
        if not folder.exists() and not folder.is_symlink(): continue
        before = capture_members(folder)
        if {key: row["sha256"] for key, row in before["files"].items()} != expected:
            raise ValueError("Existing closed diagnostic captures differ from exact current pins; explicit custody review required")
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


def archive_diagnostic(root, dest):
    receipt = {"original_path": DIAGNOSTIC_ARTIFACT, "portable_path": "diagnostics/actual-commits.exact.json", "complete": False, "problems": [], "gameplay_or_art_accepted": False}
    path = scoped_path(root, DIAGNOSTIC_ARTIFACT)
    if not path.is_file():
        receipt["problems"].append("Actual commit diagnostic missing")
    else:
        out = dest / receipt["portable_path"]
        out.parent.mkdir(parents=True, exist_ok=True)
        with out.open("xb") as stream: stream.write(path.read_bytes())
        receipt.update({"sha256": digest(out), "bytes": out.stat().st_size})
        try:
            data = decode_exact_metadata(out.read_text())
            rows = data.get("observations")
            if data.get("super_calls_per_observed_call") != 1 or data.get("max_observations") != 4 or data.get("original_four_view_assertions_preserved") is not True or not isinstance(rows, list) or not 1 <= len(rows) <= 4:
                raise ValueError("Bounded actual commit packet fields differ")
            def finite(number): return type(number) in (int, float) and math.isfinite(number)
            observed = []
            for index, row in enumerate(rows):
                if not isinstance(row, dict) or row.get("call") != index + 1 or not isinstance(row.get("reservation_id"), str) or not row["reservation_id"] or not finite(row.get("clock_before_s")) or not finite(row.get("clock_after_s")) or type(row.get("answer_accepted")) is not bool or (row.get("answer_reason") is not None and not isinstance(row.get("answer_reason"), str)) or not isinstance(row.get("scheduler_last_error_after_super"), str):
                    raise ValueError("Actual commit identity/clocks/answer missing")
                for key in ("geometry_argument", "response_argument", "answer"):
                    if not isinstance(row.get(key), dict) or row[key].get("native_type") != "Dictionary": raise ValueError("Tagged native dictionary argument/answer missing")
                overlap = row.get("starting_overlap_after_native_refusal")
                if overlap is not None:
                    if row["answer_accepted"] is not False or row["answer_reason"] != GENERIC_PROOF_EXHAUSTION or not isinstance(overlap, dict) or type(overlap.get("queried")) is not bool or not isinstance(overlap.get("error"), str):
                        raise ValueError("Conditional overlap does not follow exact original generic refusal")
                    if overlap["queried"]:
                        if overlap["error"] != "" or overlap.get("collision_mask") != 1 or overlap.get("collide_with_areas") is not False or overlap.get("maximum_hits_per_query") != 8: raise ValueError("Native overlap policy differs")
                        for key in ("actual_player_capsule", "scheduler_expanded_capsule"):
                            query = overlap.get(key)
                            if not isinstance(query, dict) or type(query.get("overlap")) is not bool or not isinstance(query.get("hits"), list) or len(query["hits"]) > 8 or query["overlap"] != bool(query["hits"]): raise ValueError("Bounded native overlap rows missing")
                    elif not overlap["error"]:
                        raise ValueError("Unqueried overlap lacks its exact native-binding refusal")
                elif row["answer_accepted"] is False and row["answer_reason"] == GENERIC_PROOF_EXHAUSTION:
                    raise ValueError("Exact generic refusal has no conditional starting observation")
                observed.append({"call": row["call"], "reservation_id": row["reservation_id"], "clock_before_s": row["clock_before_s"], "clock_after_s": row["clock_after_s"], "same_call_clock_unchanged": row["clock_before_s"] == row["clock_after_s"], "answer_accepted": row["answer_accepted"], "answer_reason": row["answer_reason"], "scheduler_last_error_after_super": row["scheduler_last_error_after_super"], "starting_overlap": overlap})
            write_json(dest / "diagnostics/actual-commits-decoded.json", data)
            receipt.update({"complete": True, "decoded_portable_path": "diagnostics/actual-commits-decoded.json", "decoded_sha256": digest(dest / "diagnostics/actual-commits-decoded.json"), "actual_observations": observed})
        except (ValueError, TypeError, KeyError, AttributeError) as error:
            receipt["problems"].append("Actual exact commit diagnostic refused: " + str(error))
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
    seen, modes, uid_presence, import_presence, unresolved, used_classes = freeze_sources(root, dest)
    helper = pathlib.Path(__file__).resolve(); shutil.copy2(helper, dest / "recorder-original.py")
    command = ["python3", "scripts/dev/dev.py", mode]
    if mode == "engine": command += ["--path", ".", "--log-file", str(raw), "--script", "res://" + FIXTURE]
    source = {"at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "cwd": str(root),
              "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
              "shared_publication": PUBLICATION, "mechanical_shared_publication": MECHANICAL_PUBLICATION,
              "api_revision": API, "command": command, "files": seen, "file_modes": modes, "source_count": len(seen),
              "component_pins": PINS, "original_fixture_sha256": PINS[ORIGINAL_FIXTURE], "uid_presence_before": uid_presence, "import_sidecar_presence_before": import_presence, "global_class_dependencies": used_classes, "unresolved_literal_references": unresolved,
              "recorder_sha256": digest(dest / "recorder-original.py"),
              "project_modes": {"original_project": "source/project.godot", "original_engine_local": "source/.cinder/local.json",
                                "headless": mode == "import", "native_view": "Shared Main Window/root viewport540x1170; ordinary fixed7.2 Camera/HUD; actual postdraw PNGs" if mode == "engine" else "Headless resource import only; no rendered capture"},
              "source_scope": "Original440 actual approach fixture plus TEST-only Scheduler subclass/writer; exact original fixture copied separately. Actual production scene/host1394 a7d9/parent1501 f36 and shared mechanical41/published43; literal resources plus actual global GDScript class dependencies, UID/import sidecars and modes. Bounded source closure, not whole project clone.",
              "test_scope": "New diagnostic resource parser/import only; no native refusal/art credit" if mode == "import" else "Passive one-super-call commit_tracking wrapper retains actual arguments/clock/native answer for at most four commits. Only exact generic proof exhaustion adds two bounded callback-free native starting-overlap queries, using actual Hero/body height/transforms and received floor exclusions. No sweep/path reproof/extra reservation query or admission. Original440 three failed lock/gallery assertions remain unchanged; partial entry pixels are archived with no art acceptance. No source repair, live HP/clock/pose/timing writes or full-route credit."}
    write_json(dest / "source.json", source)
    code, execution = run_queued(command, root, dest / "wrapper.log")
    if raw.is_file(): shutil.copy2(raw, dest / "raw.log")
    logs = {"wrapper": (dest / "wrapper.log").read_text(errors="replace")}
    if (dest / "raw.log").is_file(): logs["raw"] = (dest / "raw.log").read_text(errors="replace")
    counts = {name: log_counts(log) for name, log in logs.items()}; chosen = plain(logs.get("raw", logs["wrapper"]))
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
    clean = code == 0 and execution["child_exited"] and execution["wrapper_stream_complete"] and not execution["termination"] and not changed and not changed_modes and all(not any(row.values()) for row in counts.values())
    diagnostic_complete = mode == "engine" and code == 1 and execution["engine_banner_observed"] and execution["child_exited"] and execution["wrapper_stream_complete"] and not execution["termination"] and not changed and not changed_modes and "raw" in logs and len(summaries) == 1 and summaries[0]["failures"] == 3 and not summaries[0]["scope_complete"] and diagnostic["complete"] and not receipt["problems"] and all(row["script_errors"] == row["parse_or_load_errors"] == row["warnings"] == row["unexplained_native_errors"] == row["fail_markers"] == 0 and row["assertion_errors"] == row["native_errors"] == 3 for row in counts.values()) and all(sum(line.startswith("ERROR: " + prefix) for line in chosen.splitlines()) == 1 for prefix in EXPECTED_ASSERTIONS)
    # A complete passive packet preserves original exit1/three failed gallery
    # assertions. It does not make native mechanics or art scope accepted.
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
