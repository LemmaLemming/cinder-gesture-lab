"""Private A3-O2 host seal and one canonical queued short registration child."""
from pathlib import Path
import argparse
import contextlib
import datetime
import hashlib
import importlib.util
import json
import os
import re
import sys
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ENV = "CINDER_A3_O2_SHORT_REGISTRATION_REPORT"
FOOTER_SCOPE = "actual row/parent/unlock/entry/coherent protected Story+initial disk/entrance Retry/early Leave/disk/normal cleanup. TEST prefix12 only. Completion/stamp/contact-return/Replay NOT executed here: final verified owner evidence must be reused separately by Root acceptance. No inherited held/court/route, completion/session export, GUI, portrait or broad balance credit."


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(), parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))


def save(path, value):
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("xb") as stream:
        stream.write((json.dumps(value, indent=2, allow_nan=False) + "\n").encode())
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


class Tee:
    def __init__(self, first, second):
        self.first, self.second = first, second
    def write(self, value):
        self.second.write(value)
        return self.first.write(value)
    def flush(self):
        self.first.flush()
        self.second.flush()


def snapshot(spec, out, label):
    observations, retained = {}, {}
    blobs = out / "source-blobs"
    blobs.mkdir(exist_ok=True)
    for name in sorted(set(spec["expected"]) | set(spec["self_files"])):
        source = ROOT / name
        data = source.read_bytes() if source.is_file() else None
        digest = hashlib.sha256(data).hexdigest() if data is not None else None
        observations[name] = digest
        if data is not None:
            target = blobs / (digest + ".bin")
            if not target.exists():
                with target.open("xb") as stream:
                    stream.write(data)
            require(sha(target) == digest, "Retained source differs: " + name)
            retained[name] = {"sha256": digest, "bytes": len(data), "blob": str(target.relative_to(out))}
    save(out / (label + ".json"), observations)
    save(out / (label + "-retention.json"), retained)
    return observations


def prepared(spec, names):
    require(all(names.get(name) == digest for name, digest in spec["expected"].items()), "Fixed promoted source/config/UID differs")
    require(all(names.get(name) is not None for name in spec["self_files"]), "Runner capsule incomplete")
    for name, digest in read(HERE / "READINESS.json")["frozen_files"].items():
        require(names.get(name) == digest, "Frozen runner capsule differs: " + name)
    promotion = ROOT / spec["promotion"]["path"]
    require(sha(promotion) == spec["promotion"]["sha256"], "Exact original Root promotion required")
    receipt = read(promotion)
    owned = [row for row in receipt["cohort"] if row["kind"] == "owned"]
    require(receipt["source_commit"] == spec["source_commit"] and receipt["owned_paths"] == len(owned) == 28, "Actual selected 28-file promotion required")
    for row in owned:
        path = ROOT / row["path"]
        require(names.get(row["path"]) == row["sha256"] and path.stat().st_size == row["bytes"] and row["mode"] == "100644" and not path.is_symlink() and not path.stat().st_mode & 0o111, "Promoted byte/size/mode differs: " + row["path"])


def previous_seal(path):
    require(path.name == "seal.json" and path.parent.parent == HERE, "Explicit original seal from this capsule required")
    result, index = read(path.parent / "result.json"), read(path.parent / "evidence-index.json")
    require(result.get("closed") is True and result.get("passed") is True and type(result.get("runner_return_code")) is int and result["runner_return_code"] == 0, "Seal phase must close successfully")
    require(index.get("created_after_raw_close") is True and index["files"]["seal.json"]["sha256"] == sha(path) and index["files"]["result.json"]["sha256"] == sha(path.parent / "result.json"), "Seal/result must join original closed index")
    seal = read(path)
    require(seal.get("sealed") is True and seal.get("source_phase") == str(path.parent), "Actual seal identity required")
    return seal["names"]


def observe(out, raw, spec, names):
    native = out / "native-report.json"
    require(native.is_file(), "Actual native report required")
    save(out / "native-report-retention.json", {"path": str(native), "sha256": sha(native), "bytes": native.stat().st_size, "scope": "Original native bytes retained before interpretation; no synthetic rows or game packets."})
    printed = re.findall(r"^Retained SHORT registration report: (.+) sha256=([0-9a-f]{64})$", raw, re.M)
    require(printed == [(str(native), sha(native))], "Actual printed report path/SHA must join bytes")
    report = read(native)
    require(type(report.get("schema_version")) is int and report["schema_version"] == 1 and report.get("kind") == "a3-o2-short-canonical-registration" and report.get("accepted_content") == spec["accepted_content"], "Actual report identity differs")
    rows, checks, failed = report.get("report"), report.get("checks"), report.get("failures")
    require(type(checks) is int and type(failed) is int and isinstance(rows, list) and all(isinstance(row, dict) and type(row.get("check")) is int and type(row.get("ok")) is bool for row in rows), "Strict actual counters/rows required")
    require(checks == len(rows) > 0 and [row["check"] for row in rows] == list(range(1, checks + 1)) and failed == sum(row["ok"] is False for row in rows) == 0 and report.get("first_failure") == {}, "Actual row/counter/failure join differs")
    footer = re.findall(r"^A3-O2 SHORT canonical registration: (\d+) checks/(\d+) failures, short_scope_complete=(true|false); " + re.escape(FOOTER_SCOPE) + r"$", raw, re.M)
    require(report.get("short_scope_complete") is True and report.get("success") is True and footer == [(str(checks), str(failed), "true")], "Actual completion/footer join differs")
    expected = {"res://" + name: {"present": True, "sha256": names[name]} for name in spec["native_source_names"]}
    expected["fixture"] = {"path": "res://" + spec["fixture"], "sha256": names[spec["fixture"]], "scope": "actual executing Script resource path; no inferred Git provenance"}
    require(report.get("source_before") == report.get("source_after") == expected, "Actual nested native source/fixture observations differ from seal")
    initial = report.get("initial_closed_packet_disk")
    require(isinstance(initial, dict) and initial.get("independent_initial_disk_equal") is True, "Actual independent initial disk evidence required")
    for name in ("story", "session"):
        wire = initial.get("exact_" + name)
        require(isinstance(wire, str) and bool(wire) and type(initial.get(name + "_bytes")) is int and initial[name + "_bytes"] == len(wire.encode()) and initial.get(name + "_sha256") == hashlib.sha256(wire.encode()).hexdigest(), "Original opaque initial wire byte/SHA join differs: " + name)
    reuse = report.get("completion_replay")
    require(isinstance(reuse, dict) and reuse.get("executed_here") is False and reuse.get("completion_session_export_required") is False, "Original limited completion/Replay scope required")
    return {"checks": checks, "failures": failed, "actual_rows": len(rows), "short_scope_complete": True, "native_report_sha256": sha(native), "scope": "Actual canonical entry/entrance Retry/early Leave and protected Story/disk/cleanup only. Full old/current transport, four components and portrait remain separately reviewed owner evidence; no new execution credit."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("seal", "native"))
    parser.add_argument("--seal", type=Path)
    args = parser.parse_args()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / ("run-" + args.phase + "-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    result = {"phase": args.phase, "closed": False, "passed": False, "engine_launch_attempted": False, "owned_validation_returned": False, "canonical_validation_return_code": None}
    queue = {"queued": False, "acquired": False}
    code, spec, sealed = 2, None, None
    save(out / "result.json", result)
    print("A3-O2 verification output:", out, flush=True)
    with (out / "raw.log").open("w") as log, contextlib.redirect_stdout(Tee(sys.stdout, log)), contextlib.redirect_stderr(Tee(sys.stderr, log)):
        try:
            require((args.phase == "seal") == (args.seal is None), "Native requires explicit successful seal; seal takes none")
            spec = read(HERE / "INPUT_SPEC.json")
            current = snapshot(spec, out, "preflight-observed")
            prepared(spec, current)
            if args.phase == "seal":
                sealed = current
                save(out / "seal.json", {"sealed": True, "source_phase": str(out), "names": sealed, "scope": spec["scope"]})
            else:
                selected = args.seal.resolve()
                sealed = previous_seal(selected)
                require(current == sealed, "Current sources differ from explicit successful seal")
                save(out / "selected-seal.json", {"path": str(selected), "sha256": sha(selected)})
                module_spec = importlib.util.spec_from_file_location("cinder_a3_o2_verification_dev", ROOT / "scripts/dev/dev.py")
                require(module_spec is not None and module_spec.loader is not None, "Canonical dev module required")
                dev = importlib.util.module_from_spec(module_spec)
                sys.modules[module_spec.name] = dev
                old_bytecode = sys.dont_write_bytecode
                try:
                    sys.dont_write_bytecode = True
                    module_spec.loader.exec_module(dev)
                finally:
                    sys.dont_write_bytecode = old_bytecode
                environ = dict(os.environ)
                environ[ENV] = str(out / "native-report.json")
                context = dev.ProjectContext(root=ROOT, environ=environ)
                require(context.canonical_root == ROOT, "Canonical context must remain this integration checkout")
                require(dev.SUITES.get(spec["alias"]) == spec["fixture"] and dev.suite_paths(context, spec["alias"]) == ["res://" + spec["fixture"]], "Registered canonical alias resolves differently")
                command = [str(dev.resolve_godot(context)), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log"), "--script", "res://" + spec["fixture"]]
                save(out / "command.json", {"argv": command, "timeout_seconds_after_lock": spec["timeout_after_lock_seconds"], "environment_override": {ENV: environ[ENV]}, "canonical_CLI_equivalent": "python3 scripts/dev/dev.py test act3_o2_registration", "user_arguments": []})
                require(snapshot(spec, out, "sources-before-queue") == sealed, "Sources changed before queue")
                queue.update({"queued": True, "lock_path": str(dev.shared_lock_path(ROOT))})
                save(out / "queue.json", queue)
                try:
                    with dev.godot_lock(ROOT) as lock_fd:
                        queue["acquired"] = True
                        save(out / "queue.json", queue)
                        require(snapshot(spec, out, "sources-at-lock") == sealed, "Sources changed at lock")
                        result["engine_launch_attempted"] = True
                        save(out / "result.json", result)
                        returned = dev.run_validation(command, context, lock_fd, spec["timeout_after_lock_seconds"], detect_godot_errors=True)
                        result.update({"owned_validation_returned": True, "canonical_validation_return_code": returned, "terminal_scope": "Canonical API return, potentially synthetic timeout/script failure; not an independently exposed OS child status. Canonical dev owns its one direct child and cleanup."})
                        save(out / "result.json", result)
                        log.flush()
                        after = snapshot(spec, out, "sources-after-child")
                        result["native_observation"] = observe(out, (out / "raw.log").read_text(), spec, sealed)
                        save(out / "native-observation.json", result["native_observation"])
                        require(after == sealed, "Sources changed after owned child")
                        require(returned == 0, "Canonical owned validation must return zero")
                finally:
                    if queue["acquired"]:
                        queue["lock_context_released"] = True
                        save(out / "queue.json", queue)
            result["passed"], code = True, 0
        except KeyboardInterrupt:
            result["error"], code = "Interrupted; canonical dev owns its direct child cleanup", 130
        except Exception as error:
            result["error"] = str(error)
            print("A3-O2 verification failure:", error, flush=True)
        finally:
            if spec is not None:
                try:
                    closed = snapshot(spec, out, "sources-at-runner-close")
                    require(sealed is None or closed == sealed, "Source drift at runner close")
                except Exception as error:
                    result["close_custody_error"] = str(error)
                    result["passed"], code = False, 2
            log.flush()
            result.update({"closed": True, "runner_return_code": code, "raw_diagnostic_lines": [line for line in (out / "raw.log").read_text().splitlines() if re.search(r"^\s*(?:ERROR|WARNING|SCRIPT ERROR):|ObjectDB.*leak|Orphan.*StringName", line, re.I)], "diagnostic_scope": "Actual raw diagnostics preserved, not automatically classified clean by a zero return; Root must review them."})
            save(out / "result.json", result)
            save(out / "queue.json", queue)
            print("A3-O2 verification CLOSED code=" + str(code), flush=True)
    save(out / "evidence-index.json", {"created_after_raw_close": True, "files": {str(path.relative_to(out)): {"sha256": sha(path), "bytes": path.stat().st_size} for path in sorted(out.rglob("*")) if path.is_file()}})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
