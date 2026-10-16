"""Private A3-L1 host seal and one canonical queued short registration child."""
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
FOOTER_SCOPE = "entry/format2/routed dash/fresh Continue/entrance Retry/cleanup"


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


def previous_seal(path):
    require(path.name == "seal.json" and path.parent.parent == HERE, "Explicit original seal from this capsule required")
    result, index = read(path.parent / "result.json"), read(path.parent / "evidence-index.json")
    require(result.get("closed") is True and result.get("passed") is True and type(result.get("runner_return_code")) is int and result["runner_return_code"] == 0, "Seal phase must close successfully")
    require(index.get("created_after_raw_close") is True and index["files"]["seal.json"]["sha256"] == sha(path) and index["files"]["result.json"]["sha256"] == sha(path.parent / "result.json"), "Seal/result must join original closed index")
    seal = read(path)
    require(seal.get("sealed") is True and seal.get("source_phase") == str(path.parent), "Actual seal identity required")
    return seal["names"]


def observe(out, raw, spec, names):
    footer = re.findall(r"^Production Act3 registration: ([0-9]+) checks, ([0-9]+) failures; expected_commit=([0-9a-f]{40}); selected_scope=(.+); TEST ONLY ten-predecessor/initial-resource seeds; no route-clear or native-human claim$", raw, re.M)
    require(len(footer) == 1, "One actual existing-fixture footer required")
    checks, failures, accepted, scope = footer[0]
    require(int(checks) > 0 and int(failures) == 0 and accepted == spec["accepted_content"] and scope == FOOTER_SCOPE, "Actual footer counters/provenance/short scope differ")
    return {"actual_footer_checks": int(checks), "actual_footer_failures": int(failures), "actual_footer": footer[0], "scope": "Existing fixture stdout footer only; no structured rows/native report/source map are emitted or invented. Host retains source custody separately. TEST ten-predecessor/initial37HP/zeroammo seed; actual canonical entry, routed dash, format2 save, fresh Continue, entrance Retry and cleanup. No fatal/crossing/legacy/portrait/route credit."}


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
    print("A3-L1 verification output:", out, flush=True)
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
                module_spec = importlib.util.spec_from_file_location("cinder_a3_l1_verification_dev", ROOT / "scripts/dev/dev.py")
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
                context = dev.ProjectContext(root=ROOT, environ=environ)
                require(context.canonical_root == ROOT, "Canonical context must remain this integration checkout")
                require(dev.SUITES.get(spec["alias"]) == spec["fixture"] and dev.suite_paths(context, spec["alias"]) == ["res://" + spec["fixture"]], "Registered canonical alias resolves differently")
                command = [str(dev.resolve_godot(context)), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log"), "--script", "res://" + spec["fixture"], "--", "--entry-retry-only"]
                save(out / "command.json", {"argv": command, "timeout_seconds_after_lock": spec["timeout_after_lock_seconds"], "environment_override": {}, "canonical_alias": "act3_registration", "user_arguments": ["--entry-retry-only"]})
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
            print("A3-L1 verification failure:", error, flush=True)
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
            print("A3-L1 verification CLOSED code=" + str(code), flush=True)
    save(out / "evidence-index.json", {"created_after_raw_close": True, "files": {str(path.relative_to(out)): {"sha256": sha(path), "bytes": path.stat().st_size} for path in sorted(out.rglob("*")) if path.is_file()}})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
