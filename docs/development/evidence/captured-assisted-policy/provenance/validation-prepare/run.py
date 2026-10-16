"""Private captured-policy runner. Root promotes the exact cohort before use.

Each invocation owns one phase and one canonical queued child at most. No
default suite, automatic escalation, production promotion or recursive census.
"""
from pathlib import Path
import argparse
import contextlib
import datetime
import hashlib
import importlib.util
import json
import os
import re
import struct
import sys
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SPEC_PATH = HERE / "INPUT_SPEC.json"
SCOPE = "Fixed named subset only; no transitive closure/global UID/native acceptance or optical claim."
ENV_KEYS = ("CINDER_CAPTURED_AUTHORED_CONTROL_REPORT", "CINDER_CAPTURED_PARENT_SHELL_REPORT", "CINDER_CAPTURED_ADDITIONAL_SOURCES", "CINDER_CAPTURED_PARENT_PORTRAITS")
FOOTERS = {
    "common": r"^Captured policy candidate: (\d+) checks/(\d+) failures\. Native common contact/Store/suffix only; original C50 literal restore, authored-Assisted control and campaign flows remain separate\.$",
    "legacy": r"^Crystalman original captured-policy literals: (\d+) checks/(\d+) failures\. Literal original phase/Player\+Store and later legacy join/contact only; declared TEST host, no whole-parent campaign/route credit\.$",
    "authored": r"^Captured policy authored control: (\d+) checks/(\d+) failures; complete=(true|false); two actual fresh authored profiles/contact only\.$",
    "shell": r"^Captured policy whole parent Shell: (\d+) checks/(\d+) failures; complete=(true|false); one genuine Assisted captured warning/whole parent public boundaries only\.$",
}
REPORTS = {
    "authored": ("CINDER_CAPTURED_AUTHORED_CONTROL_REPORT", "captured-policy-enemy-authored-control"),
    "shell": ("CINDER_CAPTURED_PARENT_SHELL_REPORT", "captured-policy-whole-parent-shell"),
}


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(ok, message):
    if not ok:
        raise ValueError(message)


def read_json(path):
    def reject(value):
        raise ValueError("Nonfinite JSON scalar: " + value)
    return json.loads(path.read_text(), parse_constant=reject)


def save(path, value):
    data = (json.dumps(value, indent=2, allow_nan=False) + "\n").encode()
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("xb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


class Tee:
    def __init__(self, original, log):
        self.original, self.log = original, log
    def write(self, value):
        self.log.write(value)
        return self.original.write(value)
    def flush(self):
        self.log.flush()
        self.original.flush()


def snapshot(spec, out, label):
    """Preserve actual bytes before comparing; deduplicate within this phase."""
    names = sorted(set(spec["expected"]) | set(spec["self_files"]))
    observations, retained = {}, {}
    blobs = out / "source-blobs"
    blobs.mkdir(exist_ok=True)
    for name in names:
        source = ROOT / name
        if not source.is_file():
            observations[name] = None
            continue
        data = source.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        observations[name] = digest
        destination = blobs / (digest + ".bin")
        if not destination.exists():
            with destination.open("xb") as stream:
                stream.write(data)
        require(sha(destination) == digest, "Retained source blob differs: " + name)
        retained[name] = {"sha256": digest, "bytes": len(data), "blob": str(destination.relative_to(out))}
    save(out / (label + ".json"), observations)
    save(out / (label + "-retention.json"), retained)
    return observations


def prepared_sources(spec, observed, allow_missing):
    optional = set(spec["only_import_additions"])
    require(len(optional) == 6, "Only six declared new UID sidecars are permitted")
    for name, expected in spec["expected"].items():
        if name in optional:
            if observed[name] is None:
                require(allow_missing, "Necessary import must produce selected new UID: " + name)
            else:
                require(re.fullmatch(rb"uid://[a-z0-9]+\s*", (ROOT / name).read_bytes()) is not None, "New UID must be an actual sidecar: " + name)
        else:
            require(expected is not None and observed[name] == expected, "Exact reviewed source/config/fixture/UID differs or is missing: " + name)
    require(all(observed[name] is not None for name in spec["self_files"]), "Prepared runner capsule files must exist")
    ready = read_json(HERE / "READINESS.json")
    for name, digest in ready["frozen_files"].items():
        require(observed[name] == digest, "Runner capsule changed since READINESS: " + name)
    promotion_path = ROOT / spec["promotion_manifest"]["path"]
    require(sha(promotion_path) == spec["promotion_manifest"]["sha256"], "Root final promotion manifest changed")
    promotion = read_json(promotion_path)
    require([row["path"] for row in promotion["paths"]] == spec["cohort22"] and len(spec["cohort22"]) == 22, "Exact selected twenty-two-path cohort required")
    require(promotion["new_UIDs_allowed_absent_then_generated_by_import"] == spec["only_import_additions"], "Root named import additions differ")
    for row in promotion["paths"]:
        actual, donor = ROOT / row["path"], ROOT / row["private_source"]
        require(observed[row["path"]] == row["sha256"] and actual.stat().st_size == row["bytes"] and observed[row["private_source"]] == row["private_sha256"], "Root promoted/donor byte receipt differs: " + row["path"])
        if row["comment_only_header_normalized"]:
            require(row["path"].endswith(".gd"), "Only GDScript comment normalization is declared")
            body = lambda path: [line for line in path.read_bytes().splitlines(keepends=True) if not line.lstrip().startswith(b"#")]
            require(body(actual) == body(donor), "Root promoted noncomment lines differ: " + row["path"])
        else:
            require(actual.read_bytes() == donor.read_bytes(), "Unnormalized Root promotion must equal exact donor: " + row["path"])


def same_sources(spec, original, current, import_additions=False):
    require(set(original) == set(current), "Seal has a different fixed named source set")
    additions = []
    for name, old in original.items():
        new = current[name]
        if old == new:
            continue
        require(import_additions and name in spec["only_import_additions"] and old is None and new is not None, "Fixed named source/UID drift: " + name)
        additions.append(name)
    return additions


def load_dev():
    spec = importlib.util.spec_from_file_location("cinder_captured_policy_validation_dev", ROOT / "scripts/dev/dev.py")
    require(spec is not None and spec.loader is not None, "Canonical dev loader required")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    original = sys.dont_write_bytecode
    try:
        sys.dont_write_bytecode = True
        spec.loader.exec_module(module)
    finally:
        sys.dont_write_bytecode = original
    return module


def successful_seal(path):
    require(path.parent.parent == HERE and path.name in ("seal.json", "fixed-after-import-seal.json"), "Seal must name this runner's actual unique closed phase")
    previous = read_json(path.parent / "result.json")
    index = read_json(path.parent / "evidence-index.json")
    require(previous.get("closed") is True and previous.get("passed") is True and type(previous.get("runner_return_code")) is int and previous["runner_return_code"] == 0, "Referenced seal phase must actually be CLOSED0 and passed")
    require(index.get("created_after_raw_log_close") is True and index["files"][path.name]["sha256"] == sha(path), "Referenced seal must join its closed original evidence index")
    require(index["files"]["result.json"]["sha256"] == sha(path.parent / "result.json"), "Referenced successful terminal result must join closed index")
    seal = read_json(path)
    require(seal.get("sealed") is True and seal.get("source_phase") == str(path.parent) and isinstance(seal.get("names"), dict), "Explicit successful original source seal required")
    return seal


def native_observation(selector, out, raw, sealed, portrait):
    """Keep failed/partial observations. No synthetic native rows or booleans."""
    observed = {"selector": selector, "validation_errors": []}
    errors = observed["validation_errors"]
    def check(ok, message):
        if not ok:
            errors.append(message)
    footers = re.findall(FOOTERS[selector], raw, re.MULTILINE)
    observed["literal_footer_matches"] = footers
    check(len(footers) == 1, "Exactly one selected native footer required")
    if selector in ("common", "legacy"):
        passes = re.findall(r"^PASS: .+$", raw, re.MULTILINE)
        failures = re.findall(r"^(?:ERROR: )?FAIL: .+$", raw, re.MULTILINE)
        observed.update({"report_format": "actual-printed-counters-and-end-footer-only", "printed_pass_lines": passes, "printed_failure_lines": failures, "structured_rows_available": False, "native_complete_boolean_available": False, "qualification": "Footer is a normal-end marker; there is no structured completion flag/row array in this native source."})
        if len(footers) == 1:
            checks, failed = map(int, footers[0])
            observed.update({"checks": checks, "failures": failed})
            check(checks > 0 and failed == 0, "Nonempty zero-failure native counter required")
            check(checks == len(passes) + len(failures) and failed == len(failures), "Actual printed assertion lines must join footer counters")
        return observed
    report_path = out / "native-report.json"
    observed["report_format"] = "actual-plain-JSON-rows-and-complete"
    check(report_path.is_file(), "Native report file required")
    if not report_path.is_file():
        return observed
    observed["report"] = {"path": str(report_path), "sha256": sha(report_path), "bytes": report_path.stat().st_size}
    try:
        report = read_json(report_path)
        require(isinstance(report, dict), "Native report must be an object")
        checks, failed, rows = report.get("checks"), report.get("failures"), report.get("rows")
        require(type(checks) is int and type(failed) is int and isinstance(rows, list), "Native counters must be integers and actual rows an array")
        require(all(isinstance(row, dict) and type(row.get("ok")) is bool and type(row.get("check")) is int for row in rows), "Actual report row types differ")
        false_rows = [row for row in rows if row["ok"] is False]
        observed.update({"checks": checks, "failures": failed, "complete": report.get("complete"), "success": report.get("success"), "actual_row_count": len(rows), "actual_false_row_count": len(false_rows), "observed_first_failed_row": false_rows[0] if false_rows else None, "first_failure_field_present_in_native": "first_failure" in report})
        check(report.get("schema_version") == 1 and type(report.get("schema_version")) is int and report.get("kind") == REPORTS[selector][1], "Actual report schema/kind differs")
        check(checks == len(rows) > 0 and [row["check"] for row in rows] == list(range(1, len(rows) + 1)), "Rows must join positive exact consecutive counters")
        check(failed == len(false_rows) == 0 and report.get("complete") is True and report.get("success") is True, "Actual failures/completion/success must positively join")
        if "first_failure" in report:
            check(report["first_failure"] == (false_rows[0] if false_rows else {}), "Native first-failure field must join actual rows")
        env_name = REPORTS[selector][0]
        printed = re.findall(r"^" + env_name + r" path=(.+) sha256=([0-9a-f]{64})$", raw, re.MULTILINE)
        check(printed == [(str(report_path), sha(report_path))], "Exactly one native report path/SHA line must join retained bytes")
        check(footers == [(str(checks), str(failed), "true" if report.get("complete") is True else "false")], "Literal native footer must join actual report counters/completion")
        if selector == "shell":
            expected = {"res://" + name: value for name, value in sealed.items()}
            check(report.get("source_before") == report.get("source_after") == expected, "Actual Shell source-before/after maps must join fixed seal")
            receipts = report.get("exact_receipts")
            check(isinstance(receipts, list) and bool(receipts) and all(isinstance(value, str) and bool(value) for value in receipts), "Actual opaque Exact receipts must remain nonempty strings; no ordinary-JSON normalization")
            check(type(report.get("portrait_requested")) is bool and report["portrait_requested"] is portrait, "Native portrait request boolean must match explicit selector")
            images = report.get("portraits")
            require(isinstance(images, list), "Actual portrait receipt array required")
            check(len(images) == (1 if portrait else 0), "Only the one explicitly selected Shell portrait may be produced")
            image_observations = []
            for image in images:
                require(isinstance(image, dict) and isinstance(image.get("path"), str), "Portrait receipt type differs")
                path = Path(image["path"])
                require(path.is_absolute() and path.parent == out / "portraits" and path.name == "01-actual-captured-assisted-whole-parent-warning.png" and path.is_file() and not path.is_symlink(), "Portrait must be actual owned unique-output PNG")
                data = path.read_bytes()
                require(len(data) >= 24 and data[:8] == b"\x89PNG\r\n\x1a\n" and data[12:16] == b"IHDR", "Actual PNG signature/IHDR required")
                dimensions = list(struct.unpack(">II", data[16:24]))
                check(sha(path) == image.get("sha256") and dimensions == image.get("dimensions") == [340, 736], "Actual PNG SHA/dimensions must join native receipt")
                check(all(image.get(key) is True for key in ("paused_without_tick", "whole_packet_input_current_camera_hud_callbacks_unchanged", "menu_test_overlay_excluded_and_restored")) and image.get("native_optical_error") == "", "Actual portrait boundary booleans/optical error must join")
                image_observations.append({"path": str(path), "sha256": sha(path), "bytes": len(data), "dimensions": dimensions, "qualification": "File/receipt verification only. Root must separately inspect actual pixels."})
            save(out / "portrait-file-verification.json", {"requested": portrait, "images": image_observations, "optical_inspection_performed": False})
    except Exception as exc:
        errors.append("Report validation: " + str(exc))
    return observed


def arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("seal", "import", "parse", "native"))
    parser.add_argument("selector", nargs="?", choices=("common", "legacy", "authored", "shell"))
    parser.add_argument("--seal", type=Path)
    parser.add_argument("--promotion", type=Path, help="Seal only: exact Root final promotion manifest pinned in INPUT_SPEC")
    parser.add_argument("--portrait", action="store_true", help="Native Shell only; one new owned graphical output directory")
    return parser.parse_args()


def main():
    args = arguments()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / ("run-" + args.phase + ("-" + args.selector if args.selector else "") + "-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    result = {"phase": args.phase, "selector": args.selector, "started_at": now(), "output": str(out), "closed": False, "passed": False, "engine_launch_attempted": False, "owned_validation_returned": False, "canonical_validation_return_code": None, "scope": SCOPE}
    queue = {"queued": False, "acquired": False}
    save(out / "result.json", result)
    save(out / "queue.json", queue)
    code, spec, sealed = 2, None, None
    print("Captured-policy validation output:", out, flush=True)
    with (out / "raw.log").open("w") as log, contextlib.redirect_stdout(Tee(sys.stdout, log)), contextlib.redirect_stderr(Tee(sys.stderr, log)):
        try:
            require((args.phase in ("parse", "native")) == (args.selector is not None), "One explicit selector required for parse/native; none for seal/import")
            require(not args.portrait or (args.phase == "native" and args.selector == "shell"), "Portrait allowed only for one native Shell case")
            require((args.phase == "seal") == (args.seal is None), "Seal phase takes no prior seal; every engine phase requires explicit --seal")
            require((args.phase == "seal") == (args.promotion is not None), "Only seal phase requires explicit --promotion")
            spec = read_json(SPEC_PATH)
            observed = snapshot(spec, out, "preflight-observed-inputs")
            prepared_sources(spec, observed, args.phase in ("seal", "import"))
            if args.phase == "seal":
                require(args.promotion.resolve() == ROOT / spec["promotion_manifest"]["path"], "Explicit promotion must be the authoritative Root manifest")
                sealed = observed
                save(out / "seal.json", {"sealed": True, "created_at": now(), "source_phase": str(out), "names": sealed, "scope": SCOPE, "only_import_additions": spec["only_import_additions"], "promotion_manifest": spec["promotion_manifest"]})
                result["passed"] = True
                code = 0
            else:
                seal_path = args.seal.resolve()
                seal = successful_seal(seal_path)
                sealed = seal["names"]
                same_sources(spec, sealed, observed)
                save(out / "selected-seal.json", {"original_path": str(seal_path), "sha256": sha(seal_path), "seal": seal})
                before = snapshot(spec, out, "sources-before-queue")
                same_sources(spec, sealed, before)
                dev = load_dev()
                child_env = {key: value for key, value in os.environ.items() if key not in ENV_KEYS}
                if args.phase == "native" and args.selector in REPORTS:
                    child_env[REPORTS[args.selector][0]] = str(out / "native-report.json")
                if args.phase == "native" and args.selector == "shell":
                    child_env["CINDER_CAPTURED_ADDITIONAL_SOURCES"] = json.dumps(["res://" + name for name in sorted(sealed)])
                    if args.portrait:
                        portraits = out / "portraits"
                        portraits.mkdir(exist_ok=False)
                        child_env["CINDER_CAPTURED_PARENT_PORTRAITS"] = str(portraits)
                context = dev.ProjectContext(root=ROOT, environ=child_env)
                command = [str(dev.resolve_godot(context)), "--path", str(ROOT), "--log-file", str(out / "engine.log")]
                if not args.portrait:
                    command.append("--headless")
                timeout = 120 if args.phase == "parse" else (360 if args.phase == "native" and args.selector == "shell" else 180)
                if args.phase == "import":
                    command += ["--editor", "--quit"]
                else:
                    if args.phase == "parse":
                        command.append("--check-only")
                    command += ["--script", "res://" + spec["selectors"][args.selector]]
                    if args.portrait:
                        command += ["--", "--portrait"]
                save(out / "command.json", {"argv": command, "cwd": str(ROOT), "timeout_seconds_after_lock_acquisition": timeout, "environment_overrides": {key: child_env[key] for key in ENV_KEYS if key in child_env}, "scope": "Only listed child-specific overrides; inherited machine environment is not dumped or modified. No sandbox self-escalation."})
                queue.update({"queued": True, "queued_at": now(), "lock_path": str(dev.shared_lock_path(ROOT)), "timeout_seconds_after_acquisition": timeout})
                save(out / "queue.json", queue)
                try:
                    with dev.godot_lock(ROOT) as lock_fd:
                        queue.update({"acquired": True, "acquired_at": now()})
                        save(out / "queue.json", queue)
                        at_lock = snapshot(spec, out, "sources-at-lock")
                        same_sources(spec, sealed, at_lock)
                        result.update({"engine_launch_attempted": True, "engine_launch_attempted_at": now()})
                        save(out / "result.json", result)
                        returned = dev.run_validation(command, context, lock_fd, timeout, detect_godot_errors=True)
                        result.update({"owned_validation_returned": True, "owned_validation_returned_at": now(), "canonical_validation_return_code": returned, "terminal_scope": "Canonical API wait returned. Nonzero can be synthetic timeout/script-error; no separate OS child exit is exposed. A launch attempt flag alone does not prove a child started. Only canonical dev manages its own direct child."})
                        save(out / "result.json", result)
                        after = snapshot(spec, out, "sources-after-child")
                        additions = same_sources(spec, sealed, after, args.phase == "import")
                        prepared_sources(spec, after, False)
                        if args.phase == "import":
                            result["selected_import_uid_additions"] = additions
                finally:
                    if queue["acquired"]:
                        queue["lock_context_released_at"] = now()
                        save(out / "queue.json", queue)
                log.flush()
                if args.phase == "native":
                    observation = native_observation(args.selector, out, (out / "raw.log").read_text(), sealed, args.portrait)
                    save(out / "native-observation.json", observation)
                    result["native_observation"] = observation
                    require(not observation["validation_errors"], "Native observation joins failed; see retained observation/report/raw")
                require(returned == 0 and result["owned_validation_returned"], "Canonical owned validation must return zero")
                if args.phase == "import":
                    save(out / "fixed-after-import-seal.json", {"sealed": True, "created_at": now(), "source_phase": str(out), "names": after, "scope": SCOPE, "original_seal_sha256": sha(seal_path), "only_import_additions": spec["only_import_additions"], "actual_import_additions": additions, "promotion_manifest": spec["promotion_manifest"]})
                    sealed = after
                result["passed"] = True
                code = 0
        except KeyboardInterrupt:
            result.update({"interrupted": True, "error": "Interrupted; canonical dev owns only its direct child cleanup."})
            code = 130
        except Exception as exc:
            result["error"] = str(exc)
            print("Captured-policy runner failure:", exc, flush=True)
        finally:
            if spec is not None:
                try:
                    closed_sources = snapshot(spec, out, "sources-at-runner-close")
                    if sealed is not None:
                        same_sources(spec, sealed, closed_sources, args.phase == "import" and code != 0)
                except Exception as exc:
                    result["close_custody_error"] = str(exc)
                    result["passed"] = False
                    if code == 0:
                        code = 2
            log.flush()
            raw = (out / "raw.log").read_text()
            result["raw_diagnostic_lines"] = [line for line in raw.splitlines() if re.search(r"^\s*(?:ERROR|WARNING|SCRIPT ERROR):|ObjectDB.*leak|Orphan.*StringName", line, re.IGNORECASE)]
            result["diagnostic_qualification"] = "Retained raw diagnostics are not classified as clean merely from zero exit. Review host/editor/script/audio/native messages separately."
            result.update({"closed": True, "closed_at": now(), "runner_return_code": code})
            save(out / "result.json", result)
            save(out / "queue.json", queue)
            print("Captured-policy runner CLOSED code=" + str(code), flush=True)
    save(out / "evidence-index.json", {"created_after_raw_log_close": True, "scope": SCOPE, "files": {str(path.relative_to(out)): {"sha256": sha(path), "bytes": path.stat().st_size} for path in sorted(out.rglob("*")) if path.is_file()}})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
