"""Private A2-O1 single decision experiment: seal, then one canonical queued child. Native experiment completion never accepts the candidate."""
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
import stat
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


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
    observations, retained, metadata = {}, {}, {}
    blobs = out / "source-blobs"
    blobs.mkdir(exist_ok=True)
    for name in sorted(set(spec["expected"]) | set(spec["self_files"])):
        source = ROOT / name
        data = source.read_bytes() if source.is_file() else None
        digest = hashlib.sha256(data).hexdigest() if data is not None else None
        present = os.path.lexists(source)
        status = source.lstat() if present else None
        metadata[name] = {"exists":present,"regular":stat.S_ISREG(status.st_mode) if status else False,"symlink":stat.S_ISLNK(status.st_mode) if status else False,"mode":format(stat.S_IMODE(status.st_mode),"04o") if status else None}
        observations[name] = digest
        if data is not None:
            target = blobs / (digest + ".bin")
            if not target.exists():
                with target.open("xb") as stream:
                    stream.write(data)
            require(sha(target) == digest, "Retained source differs: " + name)
            retained[name] = {"sha256": digest, "bytes": len(data), "mode":metadata[name]["mode"], "blob": str(target.relative_to(out))}
    save(out / (label + ".json"), observations)
    save(out / (label + "-retention.json"), retained)
    save(out / (label + "-metadata.json"), metadata)
    for name, expected_mode in spec["expected_modes"].items():
        actual = metadata[name]
        require(actual["mode"] == expected_mode and (not actual["exists"] if expected_mode is None else actual["regular"] and not actual["symlink"]), "Fixed source/config/UID mode/type differs: " + name)
    for name in spec["self_files"]:
        require(metadata[name]["regular"] and not metadata[name]["symlink"] and metadata[name]["mode"] == "0644", "Regular0644 host control required: " + name)
    return observations


def prepared(spec, names):
    require(all(names.get(name) == digest for name, digest in spec["expected"].items()), "Fixed promoted source/config/UID differs")
    require(all(names.get(name) is not None for name in spec["self_files"]), "Runner capsule incomplete")
    for name, digest in read(HERE / "READINESS.json")["frozen_files"].items():
        require(names.get(name) == digest, "Frozen runner capsule differs: " + name)


def previous_seal(path):
    require(path.name == "seal.json" and path.parent.parent == HERE, "Explicit original seal from this capsule required")
    result, index = read(path.parent / "result.json"), read(path.parent / "evidence-index.json")
    require(result.get("closed") is True and result.get("passed") is True and type(result.get("runner_return_code")) is int and result["runner_return_code"] == 0, "Seal phase must close successfully")
    require(index.get("created_after_raw_close") is True and index["files"]["seal.json"]["sha256"] == sha(path) and index["files"]["result.json"]["sha256"] == sha(path.parent / "result.json"), "Seal/result must join original closed index")
    seal = read(path)
    require(seal.get("sealed") is True and seal.get("source_phase") == str(path.parent), "Actual seal identity required")
    return seal["names"]


def observe(out, raw, spec, names, case):
    native = out / "native-report.json"
    require(native.is_file(), "Actual native report absent; no reconstructed success")
    report = read(native)
    require(report.get("kind") == case["kind"], "Actual native kind differs")
    rows = report.get("rows")
    require(type(rows) is list and rows and type(report.get("checks")) is int and report["checks"] == len(rows), "Actual rows/count differ")
    require(all(type(row) is dict and type(row.get("check")) is int and row["check"] == i and type(row.get("ok")) is bool for i,row in enumerate(rows,1)), "Actual consecutive native rows required")
    require(all(type(row.get("label")) is str and row["label"] and "note" in row for row in rows), "Actual native label/note rows required")
    false = [row for row in rows if not row["ok"]]
    require(type(report.get("failures")) is int and report["failures"] == len(false) and report.get("first_failure") == (false[0] if false else {}), "Actual false count/first failure differ")
    require(type(report.get("complete")) is bool and type(report.get("success")) is bool and report["success"] == (report["complete"] and not false), "Actual completion/success differ")
    footer = case["footer"] + "%d checks, %d failures; complete=%s" % (len(rows),len(false),str(report["complete"]).lower())
    require([line for line in raw.splitlines() if line.startswith(case["footer"])] == [footer], "Actual footer differs")
    printed = re.findall(r"^" + re.escape(case["env"]) + r"=(.+) sha256=([0-9a-f]{64})$",raw,re.M)
    require(printed == [(str(native),sha(native))], "Actual physical report path/SHA differs")
    if case["args"]: require(report.get("mode") == case["args"][0], "Actual transport selector differs")
    require(report.get("candidate_qualified") is False, "Native experiment must not accept the candidate")
    decision = report.get("decision")
    require(type(decision) is str and decision in spec["decision_values"], "Actual declared design outcome required")
    if report["complete"]:
        require(decision != "UNEXECUTED", "Completed experiment needs actual design outcome")
        require(type(report.get("cases")) is list and [row.get("branch") for row in report["cases"]] == ["old12","fresh13"], "Exactly the two predeclared branches required")
    joined = {"checks":len(rows),"failures":len(false),"complete":report["complete"],"success":report["success"],"first_failure":report["first_failure"],"report_sha256":sha(native),"decision":decision,"candidate_qualified":False,"interpretation":"Native experiment success only. REJECT_EQUIVALENT rejects journal move; selected-path differences still need Root semantic review. No coverage or source acceptance."}
    save(out / "native-control-joins.json",joined)
    require(report["success"], "Actual native incomplete/failed; preserve and stop with no retry/search or old camera/raw repair")
    require(not re.search(r"^\s*(?:ERROR|WARNING|SCRIPT ERROR):|ObjectDB.*leak|Orphan.*StringName",raw,re.M|re.I), "Raw diagnostic NONCLEAN; independent qualification needed even with functional native success")
    return joined


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("seal", "native"))
    parser.add_argument("--seal", type=Path)
    parser.add_argument("--case", choices=("decision",))
    args = parser.parse_args()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / ("run-" + args.phase + "-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    result = {"phase": args.phase, "closed": False, "passed": False, "scope":"One neutral decision experiment only; native pass is never candidate acceptance", "engine_launch_attempted": False, "owned_validation_returned": False, "canonical_validation_return_code": None}
    queue = {"queued": False, "acquired": False}
    code, spec, sealed = 2, None, None
    save(out / "result.json", result)
    print("A2-O1 decision experiment output:", out, flush=True)
    with (out / "raw.log").open("w") as log, contextlib.redirect_stdout(Tee(sys.stdout, log)), contextlib.redirect_stderr(Tee(sys.stderr, log)):
        try:
            require((args.phase == "seal") == (args.seal is None), "Native requires explicit successful seal; seal takes none")
            spec = read(HERE / "INPUT_SPEC.json")
            require(str(ROOT) == spec["integration_root"] and HERE.parent == ROOT / ".cinder", "Exact flat Integration host/root required")
            require(set(spec["expected_modes"]) == set(spec["expected"]), "Each fixed input needs mode/absence observation")
            require((args.phase == "native") == (args.case is not None), "Native needs one explicit case; seal takes none")
            case = spec["cases"].get(args.case)
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
                module_spec = importlib.util.spec_from_file_location("cinder_a2_o1_decision_dev", ROOT / "scripts/dev/dev.py")
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
                environ[case["env"]] = str(out / "native-report.json")
                require(not (out / "native-report.json").exists(), "Fresh owned report destination required")
                context = dev.ProjectContext(root=ROOT, environ=environ)
                require(context.canonical_root == ROOT, "Canonical context must remain this integration checkout")
                engine = Path(dev.resolve_godot(context))
                engine_before = {"path":str(engine),"sha256":sha(engine),"bytes":engine.stat().st_size,"mode":format(stat.S_IMODE(engine.stat().st_mode),"04o"),"scope":"Actual future Root resolution metadata, not a prep-time engine selection or retained binary copy"}
                save(out / "engine-before.json",engine_before)
                command = [str(engine), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log"), "--script", "res://" + case["fixture"]]
                if case["args"]: command += ["--"] + case["args"]
                save(out / "command.json", {"argv":command,"case":args.case,"timeout_seconds_after_lock":180,"environment_override":{case["env"]:environ[case["env"]]},"canonical_api":"dev.godot_lock/run_validation"})
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
                        returned = None
                        try:
                            returned = dev.run_validation(command, context, lock_fd, spec["timeout_after_lock_seconds"], detect_godot_errors=True)
                            result.update({"owned_validation_returned": True, "canonical_validation_return_code": returned, "terminal_scope": "Canonical API return, potentially synthetic timeout/script failure; not an independently exposed OS child status. Canonical dev owns its one direct child and cleanup."})
                            save(out / "result.json", result)
                        finally:
                            log.flush()
                            after = snapshot(spec, out, "sources-after-child")
                            engine_after = {"path":str(engine),"sha256":sha(engine),"bytes":engine.stat().st_size,"mode":format(stat.S_IMODE(engine.stat().st_mode),"04o")}
                            save(out / "engine-after.json",engine_after)
                            require(all(engine_after[key] == engine_before[key] for key in engine_after), "Actual engine binary observation drift after child")
                            require(after == sealed, "Sources changed after owned child")
                        result["native_observation"] = observe(out, (out / "raw.log").read_text(), spec, sealed, case)
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
            print("A2-O1 decision experiment failure:", error, flush=True)
        finally:
            if spec is not None:
                try:
                    closed = snapshot(spec, out, "sources-at-runner-close")
                    require(sealed is None or closed == sealed, "Source drift at runner close")
                except Exception as error:
                    result["close_custody_error"] = str(error)
                    result["passed"], code = False, 2
            native = out / "native-report.json"
            if native.is_file(): save(out / "native-report-retention.json", {"path":str(native),"sha256":sha(native),"bytes":native.stat().st_size,"scope":"Original native partial/complete report retained even after refusal"})
            log.flush()
            result.update({"closed": True, "runner_return_code": code, "raw_diagnostic_lines": [line for line in (out / "raw.log").read_text().splitlines() if re.search(r"^\s*(?:ERROR|WARNING|SCRIPT ERROR):|ObjectDB.*leak|Orphan.*StringName", line, re.I)], "diagnostic_scope": "Actual raw diagnostics preserved, not automatically classified clean by a zero return; Root must review them."})
            save(out / "result.json", result)
            save(out / "queue.json", queue)
            print("A2-O1 decision experiment CLOSED code=" + str(code), flush=True)
    save(out / "evidence-index.json", {"created_after_raw_close": True, "files": {str(path.relative_to(out)): {"sha256": sha(path), "bytes": path.stat().st_size} for path in sorted(out.rglob("*")) if path.is_file()}})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
