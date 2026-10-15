#!/usr/bin/env python3
"""Inert, manifest-sealed encounter-arrangement checks through Cinder's queue.

Preparation does not import dev, launch Godot, generate UIDs or accept content.
Each later invocation selects exactly one phase and creates its own evidence.
"""
from pathlib import Path
import argparse
import contextlib
import datetime
import hashlib
import importlib.util
import json
import math
import os
import re
import sys
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
HELPER = "scripts/combat/encounter_arrangement.gd"
TEST = "tests/encounter_arrangement_smoke.gd"
DEV = "scripts/dev/dev.py"
EXACT_JSON = "scripts/campaign/exact_json.gd"
CODEC = "scripts/campaign/snapshot_codec.gd"
RUNNER = str(Path(__file__).resolve().relative_to(ROOT))
BASE_FILES = {HELPER, TEST, DEV, CODEC, "project.godot", RUNNER}
NEW_UIDS = {HELPER + ".uid", TEST + ".uid"}
PHASES = ("selected-import", "selected-parse", "selected-native")
REPORT_ENV = "CINDER_ENCOUNTER_ARRANGEMENT_REPORT"
TIMEOUT = 180
SCOPE = (
    "Only manifest-named helper/test/dev/project/runner/snapshot_codec files, "
    "optional directly referenced exact_json source, and their named GD UID "
    "sidecars. No recursive dependency, global/dynamic resource, class-name, "
    "UID, import, level or evidence-bank census. The queued editor import can "
    "change engine metadata outside this observed subset. Parser checks the "
    "test with its literal helper preload; native evidence covers only its "
    "actual reported assertions. No level acceptance, route, visual, owner "
    "consumer adoption or legacy Challenge integration credit."
)
HEX = re.compile(r"[0-9a-f]{64}\Z")
REPORT_LINE = re.compile(
    r"^CINDER_ENCOUNTER_ARRANGEMENT_REPORT path=(.+) sha256=([0-9a-f]{64})$",
    re.MULTILINE,
)
FOOTER_LINE = re.compile(
    r"^Encounter arrangement smoke: (\d+) checks/(\d+) failures; complete=(true|false); pure metadata only$",
    re.MULTILINE,
)


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pairs(items):
    result = {}
    for key, value in items:
        if key in result:
            raise ValueError("Duplicate JSON key: " + key)
        result[key] = value
    return result


def plain_json(path, size_limit):
    data = path.read_bytes()
    if len(data) > size_limit:
        raise ValueError("JSON exceeds bounded size: " + str(path))
    def invalid_constant(value):
        raise ValueError("Nonfinite JSON constant: " + value)
    value = json.loads(data.decode("utf-8"), object_pairs_hook=pairs,
                       parse_constant=invalid_constant)
    def check(item):
        if type(item) is int and abs(item) > 9007199254740991:
            raise ValueError("JSON integer exceeds plain safe range")
        if type(item) is float and not math.isfinite(item):
            raise ValueError("JSON number must be finite")
        if isinstance(item, dict):
            for child in item.values():
                check(child)
        elif isinstance(item, list):
            for child in item:
                check(child)
    check(value)
    return value


def source_path(relative):
    path = ROOT / relative
    if path.resolve(strict=False) != path or not path.is_relative_to(ROOT):
        raise ValueError("Named source must be a physical Root file: " + relative)
    return path


def valid_sha(value):
    return isinstance(value, str) and HEX.fullmatch(value) is not None


def load_manifest(path, phase):
    manifest = plain_json(path, 65536)
    if (not isinstance(manifest, dict) or type(manifest.get("schema_version")) is not int
            or manifest["schema_version"] != 1):
        raise ValueError("A schema_version 1 explicit Root manifest is required")
    if manifest.get("sealed") is not True or not manifest.get("sealed_by"):
        raise ValueError("Root must explicitly seal the promoted source manifest")
    if manifest.get("root") != str(ROOT):
        raise ValueError("Manifest Root does not match this integration checkout")
    files = manifest.get("files")
    if not isinstance(files, dict) or set(files) not in (BASE_FILES, BASE_FILES | {EXACT_JSON}):
        raise ValueError("Manifest must contain only the fixed named source subset")
    if not all(valid_sha(value) for value in files.values()):
        raise ValueError("Every promoted source needs an exact lowercase SHA256")
    test_text = source_path(TEST).read_text(encoding="utf-8")
    if not re.search(r'preload\s*\(\s*[\"\']res://scripts/combat/encounter_arrangement\.gd[\"\']\s*\)', test_text):
        raise ValueError("Selected parser requires the test's literal helper preload")
    references_exact = "res://" + EXACT_JSON in test_text
    if references_exact != (EXACT_JSON in files):
        raise ValueError("Pin exact_json iff this test directly references its URI")
    expected_uids = NEW_UIDS | {CODEC + ".uid"} | ({EXACT_JSON + ".uid"} if references_exact else set())
    uids = manifest.get("named_uids")
    if not isinstance(uids, dict) or set(uids) != expected_uids:
        raise ValueError("Manifest named UID subset is incomplete or too broad")
    for relative, expected in uids.items():
        if expected is None:
            if phase != "selected-import" or relative not in NEW_UIDS:
                raise ValueError("Only the two new UIDs may be absent at selected-import")
            if source_path(relative).exists():
                raise ValueError("Already-present UID must be sealed: " + relative)
        elif not valid_sha(expected):
            raise ValueError("Existing named UID requires SHA256: " + relative)
    return manifest


def snapshot(manifest):
    names = sorted(set(manifest["files"]) | set(manifest["named_uids"]))
    files, missing = {}, []
    for relative in names:
        path = source_path(relative)
        if path.is_file():
            files[relative] = sha(path)
        else:
            missing.append(relative)
    return {"observed_at": now(), "files": files, "missing": missing,
            "qualification": SCOPE}


def assert_seal(manifest, observation):
    expected = dict(manifest["files"])
    expected.update({key: value for key, value in manifest["named_uids"].items()
                     if value is not None})
    allowed_absent = sorted(key for key, value in manifest["named_uids"].items()
                            if value is None)
    if observation["files"] != expected or observation["missing"] != allowed_absent:
        raise ValueError("Named source/UID observation differs from Root-sealed manifest")


def delta(before, after):
    left, right = before["files"], after["files"]
    return {
        "changed": sorted(key for key in left.keys() & right.keys() if left[key] != right[key]),
        "added": sorted(right.keys() - left.keys()),
        "removed": sorted(left.keys() - right.keys()),
        "missing_after": after["missing"],
    }


def check_report(path, raw, manifest):
    report = plain_json(path, 524288)
    if not isinstance(report, dict):
        raise ValueError("Native report must be a JSON object")
    checks, failures = report.get("checks"), report.get("failures")
    rows = report.get("rows")
    if type(report.get("schema_version")) is not int or report["schema_version"] != 1:
        raise ValueError("Native report schema must be version 1")
    if type(checks) is not int or checks <= 0 or type(failures) is not int or failures < 0:
        raise ValueError("Native checks/failures are missing or invalid")
    if not isinstance(rows, list) or len(rows) != checks:
        raise ValueError("Native rows must individually account for every reported check")
    if any(not isinstance(row, dict) or type(row.get("check")) is not int
           or row["check"] < 0 or type(row.get("ok")) is not bool
           or not isinstance(row.get("label"), str) or not row["label"] for row in rows):
        raise ValueError("Native rows require check index, actual boolean and label")
    failed_rows = [row for row in rows if not row["ok"]]
    if failures != len(failed_rows):
        raise ValueError("Native failure count differs from actual false rows")
    if report.get("first_failure") != (failed_rows[0] if failed_rows else {}):
        raise ValueError("Native first_failure differs from the exact first false row or {}")
    if type(report.get("complete")) is not bool or type(report.get("success")) is not bool:
        raise ValueError("Native complete/success must be actual booleans")
    if report["success"] != (report["complete"] and failures == 0):
        raise ValueError("Native success does not join complete and failure count")
    expected_sources = {"res://" + name: manifest["files"][name] for name in (HELPER, TEST)}
    for field in ("source_observations_before", "source_observations_after"):
        if report.get(field) != expected_sources:
            raise ValueError("Native " + field + " does not join sealed helper/test")
    report_lines, footer_lines = REPORT_LINE.findall(raw), FOOTER_LINE.findall(raw)
    digest = sha(path)
    if report_lines != [(str(path), digest)]:
        raise ValueError("Exactly one printed native report path/SHA must join actual bytes")
    if footer_lines != [(str(checks), str(failures), str(report["complete"]).lower())]:
        raise ValueError("Exactly one actual native completion footer must join report counts")
    return {"path": str(path), "sha256": digest, "checks": checks,
            "failures": failures, "first_failure": report["first_failure"],
            "complete": report["complete"], "success": report["success"],
            "rows_count": len(rows), "actual_false_rows_count": len(failed_rows),
            "source_observations_before": report["source_observations_before"],
            "source_observations_after": report["source_observations_after"],
            "raw_report_line_join": True, "raw_footer_join": True}


class Tee:
    def __init__(self, original, log):
        self.original, self.log = original, log
    def write(self, value):
        self.log.write(value)
        return self.original.write(value)
    def flush(self):
        self.log.flush()
        self.original.flush()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=PHASES)
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / (args.phase + "-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    def save(name, value):
        (out / name).write_text(json.dumps(value, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    manifest_path = args.manifest.resolve()
    queue = {"queued": False, "acquired": False,
             "timeout_seconds_after_acquisition": TIMEOUT}
    lifecycle = {"state": "PREFLIGHT", "submitted_at": now(),
                 "engine_started_via_dev": False, "owned_child_terminal": False,
                 "process_signal_scope": "Canonical dev.run_validation owns and waits its direct child only; no foreign signals, process-group signals or lock deletion.",
                 "owned_child_pid": None,
                 "pid_limit": "Canonical run_validation encapsulates its child PID and does not expose it to this runner."}
    result = {"schema_version": 1, "phase": args.phase, "output_directory": str(out),
              "manifest_path": str(manifest_path), "qualification": SCOPE,
              "native_report": None, "engine_return_code": None,
              "return_code_provenance": "Canonical run_validation 0 proves its owned child wait returned 0; nonzero can be a synthetic timeout/script-error return, whose actual child exit status is not exposed by this API.",
              "closure_scope": "closed describes this runner invocation; owned_child_terminal separately records actual canonical validation return/interruption closure.",
              "closed": False, "passed": False}
    save("command.json", {"constructed": False})
    save("queue.json", queue)
    save("lifecycle.json", lifecycle)
    save("result.json", result)
    baseline, manifest = None, None
    wrapper_code, code = None, 2
    print("Unique encounter-arrangement evidence:", out, flush=True)
    with (out / "raw.log").open("w", encoding="utf-8") as log, \
            contextlib.redirect_stdout(Tee(sys.stdout, log)), \
            contextlib.redirect_stderr(Tee(sys.stderr, log)):
        try:
            manifest = load_manifest(manifest_path, args.phase)
            manifest_sha = sha(manifest_path)
            result["manifest_sha256"] = manifest_sha
            save("manifest-used.json", manifest)
            baseline = snapshot(manifest)
            save("sources-before-queue.json", baseline)
            assert_seal(manifest, baseline)
            spec = importlib.util.spec_from_file_location("cinder_encounter_arrangement_dev", source_path(DEV))
            dev = importlib.util.module_from_spec(spec)
            sys.modules[spec.name] = dev
            original_bytecode_policy = sys.dont_write_bytecode
            try:
                sys.dont_write_bytecode = True
                spec.loader.exec_module(dev)
            finally:
                sys.dont_write_bytecode = original_bytecode_policy
            child_env = dict(os.environ)
            child_env.pop(REPORT_ENV, None)
            report_path = out / "native-report.json"
            if args.phase == "selected-native":
                child_env[REPORT_ENV] = str(report_path)
            context = dev.ProjectContext(root=ROOT, environ=child_env)
            godot = str(dev.resolve_godot(context))
            command = [godot, "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log")]
            if args.phase == "selected-import":
                command.extend(["--editor", "--import"])
            else:
                command.extend(["--script", "res://" + TEST])
                if args.phase == "selected-parse":
                    command.append("--check-only")
            save("command.json", {"constructed": True, "argv": command, "cwd": str(ROOT),
                                  "timeout_seconds_after_acquisition": TIMEOUT,
                                  "child_only_report_environment": {REPORT_ENV: str(report_path)} if args.phase == "selected-native" else {},
                                  "inherited_environment": "Other values supplied by canonical ProjectContext; not dumped or mutated."})
            queue.update({"queued": True, "queued_at": now(), "shared_lock_path": str(dev.shared_lock_path(ROOT))})
            lifecycle["state"] = "QUEUED"
            save("queue.json", queue)
            save("lifecycle.json", lifecycle)
            with dev.godot_lock(context.root) as lock_fd:
                queue.update({"acquired": True, "acquired_at": now()})
                save("queue.json", queue)
                at_lock = snapshot(manifest)
                save("sources-at-lock.json", at_lock)
                assert_seal(manifest, at_lock)
                if sha(manifest_path) != manifest_sha:
                    raise ValueError("Root manifest drifted while queued")
                lifecycle.update({"state": "RUNNING", "engine_started_via_dev": True,
                                  "engine_started_at": now()})
                save("lifecycle.json", lifecycle)
                wrapper_code = dev.run_validation(command, context, lock_fd, TIMEOUT,
                                                  detect_godot_errors=True)
                lifecycle.update({"owned_child_terminal": True, "owned_child_terminal_at": now(),
                                  "dev_return_code": wrapper_code})
                save("lifecycle.json", lifecycle)
                after = snapshot(manifest)
                save("sources-after-child.json", after)
                change = delta(at_lock, after)
                save("source-delta.json", change)
                result["source_delta"] = change
                allowed_additions = {name for name, value in manifest["named_uids"].items()
                                     if value is None} if args.phase == "selected-import" else set()
                if change["changed"] or change["removed"] or set(change["added"]) - allowed_additions:
                    raise ValueError("Named sources drifted during owned engine child")
                if after["missing"]:
                    raise ValueError("Closed phase still lacks named source/UID files")
                if sha(manifest_path) != manifest_sha:
                    raise ValueError("Root manifest drifted during owned engine child")
                result["named_source_closure"] = {
                    "queued_to_lock_equal": baseline["files"] == at_lock["files"],
                    "lock_to_terminal_equal_except_two_named_import_additions": True,
                    "qualified_scope": SCOPE,
                }
            queue["runner_lock_context_released_at"] = now()
            save("queue.json", queue)
            result["engine_return_code"] = wrapper_code
            log.flush()
            if args.phase == "selected-native" and report_path.is_file():
                result["native_report"] = check_report(report_path, (out / "raw.log").read_text(encoding="utf-8"), manifest)
            if wrapper_code != 0:
                raise ValueError("Canonical owned validation returned " + str(wrapper_code))
            if not (out / "engine.log").is_file():
                raise ValueError("Owned engine did not leave its uniquely named engine log")
            engine_text = (out / "engine.log").read_text(encoding="utf-8", errors="replace")
            if re.search(r"^(?:ERROR:|SCRIPT ERROR:|Parse Error:)", engine_text, re.MULTILINE):
                raise ValueError("Owned engine log contains error diagnostics")
            if args.phase == "selected-native":
                if result["native_report"] is None:
                    raise ValueError("Owned native test did not leave its actual report")
                if result["native_report"]["complete"] is not True or result["native_report"]["success"] is not True:
                    raise ValueError("Actual native report is incomplete or has failed assertion rows")
                result["native_join"] = {"actual_dev_owned_terminal_zero": True,
                                         "report_and_footer_and_source_observations_join": True}
            result["passed"] = True
            code = 0
        except KeyboardInterrupt:
            # run_validation itself stops and waits its own child on interruption.
            lifecycle["interrupted_at"] = now()
            if lifecycle["engine_started_via_dev"]:
                lifecycle.update({"owned_child_terminal": True,
                                  "owned_child_terminal_at": now(),
                                  "terminal_reason": "Canonical run_validation interruption handler stopped and waited its owned direct child."})
            result["error"] = "Interrupted; canonical dev handles only its owned validation child."
            code = 130
        except Exception as exc:
            result["error"] = str(exc)
            print("Encounter-arrangement evidence failed:", exc, file=sys.stderr, flush=True)
        finally:
            # No direct subprocess or foreign-process/lock cleanup is performed here.
            if manifest is not None and baseline is not None and not (out / "sources-after-child.json").exists():
                try:
                    save("sources-after-stop.json", snapshot(manifest))
                except Exception as exc:
                    result["after_stop_snapshot_error"] = str(exc)
            result["engine_return_code"] = wrapper_code
            result.update({"closed": True, "closed_at": now(), "runner_return_code": code})
            lifecycle.update({"state": "CLOSED", "closed_at": result["closed_at"],
                              "runner_return_code": code,
                              "owned_child_terminal": lifecycle["owned_child_terminal"]})
            save("queue.json", queue)
            save("lifecycle.json", lifecycle)
            save("result.json", result)
            print("Encounter-arrangement phase CLOSED runner_return_code=" + str(code), flush=True)
    # Index after raw log is closed. Never claim completion from intended assertions.
    records = {path.name: {"path": str(path), "sha256": sha(path), "bytes": path.stat().st_size}
               for path in sorted(out.iterdir()) if path.is_file()}
    save("evidence-index.json", {"schema_version": 1, "created_after_closed": True,
                                "closure_scope": "After this runner invocation and raw log are closed; result/lifecycle distinguish preflight failure from owned-child terminal evidence.",
                                "phase": args.phase, "output_directory": str(out),
                                "qualification": SCOPE, "files": records,
                                "acceptance_credit": False})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
