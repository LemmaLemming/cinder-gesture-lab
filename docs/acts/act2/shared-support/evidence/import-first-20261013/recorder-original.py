#!/usr/bin/env python3
"""Root-run focused B02 Shell recorder; prepared only, never imported/invoked by author.
From the registered assigned checkout, after all fixture/new resources are frozen:
  python3 /private/tmp/cinder_a2_b02_shell_record.py --mode engine --manifest /private/tmp/a2_b02_shell_frozen_record_manifest.json --output-dir docs/acts/act2/shared-support/evidence/shell-native-first
Resource import is a separate explicit --mode import with a fresh output directory.
Only scripts/dev/dev.py owns Godot queue admission; no source-only Godot arguments.
"""
import argparse
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

PUBLICATION = "26f59b28007c68872b1a9870db675b5ed2f3c2e4"
API = "campaign-shared-56"
ASSIGNED_CHECKOUT = "/Users/howardchen/.codex/worktrees/campaign-act2/video game idea"
FIXTURES = ("tests/acts/act2/shared_support/sampled_circle_shell_smoke.gd",)
OUTPUT_ROOT = "docs/acts/act2/shared-support/evidence"
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".json", ".py", ".import"}
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
STARTED_JOB_LIMIT_S = 180.0  # Begins only after the Godot banner, never queue wait.


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
    assertion_errors = sum(re.search(r"\bFAIL(?:\s|:)", row) is not None for row in errors)
    return {"script_errors": len(re.findall(r"^\s*SCRIPT ERROR:", log, re.M)),
            "parse_or_load_errors": len(re.findall(r"^.*(?:Parse Error|Compilation failed|Failed to load script).*$", log, re.M)),
            "native_errors": len(errors), "assertion_errors": assertion_errors,
            "unexplained_native_errors": len(errors) - assertion_errors,
            "fail_markers": len(re.findall(r"\bFAIL(?:\s|:)", log)),
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


def freeze_sources(root, dest, seeds):
    pending, files, modes, uids, imports, unresolved, used_classes = list(seeds), {}, {}, {}, {}, set(), {}
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


def load_manifest(path, root):
    # Closed preparation schema. Missing/unfrozen resources refuse BEFORE any
    # output creation or queued job. No placeholder pin can become native credit.
    if not path.is_file() or path.is_symlink():
        raise ValueError("Actual frozen manifest must be an original regular file")
    def unique_pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError("Duplicate manifest key: " + key)
            result[key] = value
        return result
    value = json.loads(path.read_text(), object_pairs_hook=unique_pairs)
    required = {"schema_version", "publication", "api_revision", "fixture", "component_pins",
                "new_resources", "source_scope", "test_scope", "summary_prefix", "assertion_reporting"}
    optional = {"script_args", "mechanical_publication"}
    if not isinstance(value, dict) or set(value) - required - optional or required - set(value):
        raise ValueError("Frozen manifest schema keys differ")
    if type(value["schema_version"]) is not int or value["schema_version"] != 1 or value["publication"] != PUBLICATION or value["api_revision"] != API or value["fixture"] not in FIXTURES:
        raise ValueError("Frozen manifest must name exact Shared56 and the sole planned B02 Shell smoke fixture")
    pins, resources = value["component_pins"], value["new_resources"]
    fixture = value["fixture"]
    if (not isinstance(pins, dict) or fixture not in pins or not isinstance(resources, list) or
            not resources or fixture not in resources or any(not isinstance(n, str) for n in resources) or
            len(resources) != len(set(resources)) or not set(resources) <= set(pins)):
        raise ValueError("Actual fixture and every new resource must precede frozen manifest entries")
    for name, expected in pins.items():
        if not isinstance(name, str) or not isinstance(expected, str) or re.fullmatch(r"[0-9a-f]{64}", expected) is None:
            raise ValueError("Every source pin must be an exact original SHA256")
        actual = scoped_path(root, name)
        if not actual.is_file() or actual.is_symlink() or digest(actual) != expected:
            raise ValueError("Frozen original missing/differs: " + name)
    for name in resources:
        if not name.startswith(("scripts/acts/act2/", "scenes/acts/act2/", "assets/acts/act2/", "data/campaign/act2/", "tests/acts/act2/")):
            raise ValueError("New B02 Shell resource must be an owned resource: " + name)
    for name in ("source_scope", "test_scope", "summary_prefix"):
        if not isinstance(value[name], str) or not value[name].strip() or "\n" in value[name] and name == "summary_prefix":
            raise ValueError("Frozen scope/footer must be explicit and nonempty")
    if value["assertion_reporting"] not in ("count-only", "per-check-pass"):
        raise ValueError("Frozen fixture assertion reporting must be exact, never auto-inferred")
    args = value.get("script_args", [])
    if not isinstance(args, list) or any(not isinstance(x, str) or "\0" in x for x in args):
        raise ValueError("Fixture arguments must be a closed string list")
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("engine", "import"), required=True)
    parser.add_argument("--graphical", action="store_true", help="Explicit engine-only actual viewport; default remains headless")
    parser.add_argument("--manifest", type=pathlib.Path, required=True)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()
    if args.graphical and args.mode != "engine":
        parser.error("--graphical is supported only with explicit --mode engine")
    root = pathlib.Path.cwd().resolve()
    if root != pathlib.Path(ASSIGNED_CHECKOUT).resolve():
        raise SystemExit("Invoke only at the registered Act2 checkout")
    manifest_path = args.manifest.resolve()
    manifest = load_manifest(manifest_path, root)
    fixture = manifest["fixture"]
    if args.mode == "import" and (not set(FIXTURES) <= set(manifest["component_pins"]) or not set(FIXTURES) <= set(manifest["new_resources"])):
        raise SystemExit("Single new-resource import requires the actual frozen B02 Shell smoke fixture plus all declared new resources")
    if subprocess.run(["git", "merge-base", "--is-ancestor", PUBLICATION, "HEAD"], cwd=root).returncode != 0:
        raise SystemExit("Root must actually preserve-adopt exact Shared56 before this job")
    dest = scoped_path(root, args.output_dir)
    evidence_root = scoped_path(root, OUTPUT_ROOT)
    if dest == evidence_root or not dest.is_relative_to(evidence_root):
        raise SystemExit("Use a new B02 Shell evidence child directory for every import/native/retry")
    parts = dest.relative_to(evidence_root).parts
    if any(re.fullmatch(r"[a-z0-9][a-z0-9-]*", name) is None for name in parts):
        raise SystemExit("Evidence directory components must be lowercase labels")
    raw = root / ".cinder" / ("a2-b02-shell-" + "-".join(parts) + ".log") if args.mode == "engine" else None
    if dest.exists() or dest.is_symlink() or raw is not None and (raw.exists() or raw.is_symlink()):
        raise SystemExit("Refuse replacing original evidence or raw-log path")
    pins = manifest["component_pins"]
    seeds = list(pins) + ["project.godot", "scripts/dev/dev.py", ".cinder/local.json"]
    for name in seeds:
        if not scoped_path(root, name).is_file():
            raise SystemExit("Actual resource/configuration missing before frozen capture: " + name)
    dest.mkdir(parents=True, exist_ok=False)
    (dest / ".gdignore").write_text("", encoding="utf-8")
    files, modes, uids, imports, unresolved, used_classes = freeze_sources(root, dest, seeds)
    helper = pathlib.Path(__file__).resolve()
    shutil.copyfile(helper, dest / "recorder-original.py")
    (dest / "recorder-original.py").chmod(stat.S_IMODE(helper.stat().st_mode))
    shutil.copyfile(manifest_path, dest / "manifest-original.json")
    (dest / "manifest-original.json").chmod(stat.S_IMODE(manifest_path.stat().st_mode))
    command = ["python3", "scripts/dev/dev.py", args.mode]
    if args.mode == "engine":
        command += ["--path", ".", "--log-file", str(raw)]
        if not args.graphical:
            command += ["--headless"]
        command += ["--script", "res://" + fixture]
        if manifest.get("script_args"):
            command += ["--"] + manifest["script_args"]
    import_scope = "Explicit new-resource import and exact generated metadata custody only; no native mechanics, pixels or level acceptance"
    test_scope = manifest["test_scope"] if args.mode == "engine" else import_scope
    source = {"at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "cwd": str(root),
              "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
              "shared_publication": PUBLICATION, "mechanical_shared_publication": manifest.get("mechanical_publication"),
              "api_revision": API, "command": command, "mode": args.mode, "component_pins": pins,
              "new_resources": manifest["new_resources"], "manifest_sha256": digest(dest / "manifest-original.json"),
              "files": files, "file_modes": modes, "source_count": len(files), "uid_presence_before": uids,
              "import_sidecar_presence_before": imports, "global_class_dependencies": used_classes,
              "unresolved_literal_references": unresolved, "recorder_sha256": digest(dest / "recorder-original.py"),
              "project_modes": {"project_settings_original": "source/project.godot", "local_engine_original": "source/.cinder/local.json",
                                "native_headless": args.mode == "import" or not args.graphical, "graphical_explicit": args.graphical,
                                "pixels": "Explicit graphical engine viewport; actual images/metadata and independent pixel review required, no automatic art credit" if args.graphical else "No graphical/pixel acceptance from this headless recorder"},
              "source_scope": manifest["source_scope"], "test_scope": test_scope,
              "import_requested": args.mode == "import", "assertion_reporting": manifest["assertion_reporting"]}
    write_json(dest / "source.json", source)
    code, watch = run_queued(command, root, dest / "wrapper.log")
    if raw is not None and raw.is_file():
        shutil.copyfile(raw, dest / "raw.log")
    logs = {"wrapper": (dest / "wrapper.log").read_text(errors="replace")}
    if (dest / "raw.log").is_file():
        logs["raw"] = (dest / "raw.log").read_text(errors="replace")
    counts = {name: log_counts(log) for name, log in logs.items()}
    summary = re.compile(r"^" + re.escape(manifest["summary_prefix"]) + r": (\d+) checks, (\d+) failures;(.*)$", re.M)
    footers = {name: [{"checks": int(a), "failures": int(b), "scope": tail.strip()}
                      for a, b, tail in summary.findall(plain(log))] for name, log in logs.items()}
    passes = {name: len(re.findall(r"^PASS:", plain(log), re.M)) for name, log in logs.items()}
    changed = [name for name, before in files.items()
               if not scoped_path(root, name).is_file() or digest(scoped_path(root, name)) != before]
    changed_modes = [name for name, before in modes.items() if not scoped_path(root, name).is_file()
                     or oct(stat.S_IMODE(scoped_path(root, name).stat().st_mode)) != before["stat_mode"]]
    uid_presence_changes = {name: {"before": existed, "after": scoped_path(root, name).is_file()}
                            for name, existed in uids.items() if scoped_path(root, name).is_file() != existed}
    import_presence_changes = {name: {"before": existed, "after": scoped_path(root, name).is_file()}
                               for name, existed in imports.items() if scoped_path(root, name).is_file() != existed}
    generated = {}
    for name, existed in uids.items():
        path = scoped_path(root, name)
        if not existed and path.is_file():
            mode = stat.S_IMODE(path.stat().st_mode)
            generated[name] = {"sha256": digest(path), "stat_mode": oct(mode), "executable_bits": mode & 0o111,
                               "identity": path.read_text().strip()}
            copy = dest / "generated-after-job" / name
            copy.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, copy)
            copy.chmod(mode)
    clean = (code == 0 and not changed and not changed_modes and
             all(not any(row.values()) for row in counts.values()) and
             watch["engine_banner_observed"] and watch["child_exited"] and watch["wrapper_stream_complete"] and not watch["termination"])
    if args.mode == "import":
        complete = clean  # Import has no invented native footer or gameplay credit.
    else:
        complete = (clean and "raw" in logs and not generated and not uid_presence_changes and not import_presence_changes and
                    all(len(rows) == 1 and rows[0]["checks"] > 0 and rows[0]["failures"] == 0 and
                        passes[name] == (0 if manifest["assertion_reporting"] == "count-only" else rows[0]["checks"])
                        for name, rows in footers.items()) and footers["wrapper"] == footers.get("raw"))
    chosen = logs.get("raw", logs["wrapper"])
    result = {"exit_code": code, "mode": args.mode, "scope_complete": complete, "test_scope": test_scope,
              "job_watch": watch, "log_counts": counts, "summaries": footers.get("raw", footers["wrapper"]),
              "footer_by_log": footers, "pass_line_counts": passes, "source_count": len(files),
              "sources_unchanged": not changed and not changed_modes, "changed_source_paths": changed,
              "changed_file_mode_paths": changed_modes, "uid_additions_after_job": generated,
              "uid_presence_changes": uid_presence_changes, "import_presence_changes": import_presence_changes,
              "assertion_reporting": manifest["assertion_reporting"], "source_sha256": digest(dest / "source.json"),
              "wrapper_sha256": digest(dest / "wrapper.log"), "raw_sha256": digest(dest / "raw.log") if (dest / "raw.log").is_file() else None,
              "raw_wrapper_equal": (dest / "raw.log").read_bytes() == (dest / "wrapper.log").read_bytes() if "raw" in logs else None,
              "import_qualification": "Separate import only, no native scope" if args.mode == "import" else "Unexpected native metadata additions require separate diagnosis/import; originals preserved, never backfilled",
              "result_lines": [row for row in plain(chosen).splitlines() if re.search(r"checks|failures|SCRIPT ERROR:|ERROR:|WARNING:|FAIL:", row)]}
    write_json(dest / "result.json", result)
    print(json.dumps({key: value for key, value in result.items() if key != "result_lines"}, sort_keys=True))
    return code if code else (0 if complete else 1)


if __name__ == "__main__":
    sys.exit(main())
