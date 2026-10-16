"""Private A1-L3 existing-registration verification only; Root promotes first."""
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
    def write(self, text):
        self.second.write(text)
        return self.first.write(text)
    def flush(self):
        self.first.flush()
        self.second.flush()


def snapshot(spec, out, label, promotion):
    observations, retained = {}, {}
    blobs = out / "source-blobs"
    blobs.mkdir(exist_ok=True)
    names = set(spec["expected"]) | set(spec["self_files"]) | {spec["promotion_manifest"]["path"], promotion["path"]}
    for name in sorted(names):
        path = ROOT / name
        require(not path.is_symlink(), "Symlink source refused: " + name)
        data = path.read_bytes() if path.is_file() else None
        digest = hashlib.sha256(data).hexdigest() if data is not None else None
        observations[name] = digest
        if data is not None:
            target = blobs / (digest + ".bin")
            if not target.exists():
                with target.open("xb") as stream: stream.write(data)
            require(sha(target) == digest, "Retained source differs: " + name)
            retained[name] = {"sha256": digest, "bytes": len(data), "blob": str(target.relative_to(out))}
    save(out / (label + ".json"), observations)
    save(out / (label + "-retention.json"), retained)
    return observations


def prepared(spec, names, promotion):
    require(all(names.get(n) == h for n, h in spec["expected"].items()), "Fixed named promoted/runtime/config/UID differs")
    for name, digest in read(HERE / "READINESS.json")["frozen_files"].items():
        require(names.get(name) == digest, "Frozen capsule differs: " + name)
    require(names.get(spec["promotion_manifest"]["path"]) == spec["promotion_manifest"]["sha256"], "Private staging manifest differs")
    require(names.get(promotion["path"]) == promotion["sha256"], "Supplied Root promotion receipt differs")
    cohort = read(ROOT / promotion["path"]).get("cohort")
    require(isinstance(cohort, list) and len(cohort) == len(spec["cohort"]), "Exact12 Root promotion rows required")
    got = {r["path"]: r for r in cohort}
    require(len(got) == len(cohort) and set(got) == {r["path"] for r in spec["cohort"]}, "Root promotion path set differs")
    for row in spec["cohort"]:
        path = ROOT / row["path"]
        require(all(got[row["path"]].get(k) == row[k] for k in ("sha256", "bytes", "mode")), "Root promotion cohort differs: " + row["path"])
        require(path.is_file() and not path.is_symlink() and path.stat().st_size == row["bytes"] and not path.stat().st_mode & 0o111, "Promoted type/size/mode differs: " + row["path"])
    for name, row in spec["genuine_uid_states"].items():
        require((ROOT / name).read_text().strip() == row["value"], "Genuine existing UID changed: " + name)


def previous_seal(path):
    require(path.name == "seal.json" and path.parent.parent == HERE, "Explicit seal from this capsule required")
    result, index = read(path.parent / "result.json"), read(path.parent / "evidence-index.json")
    require(result.get("closed") is True and result.get("passed") is True and type(result.get("runner_return_code")) is int and result["runner_return_code"] == 0, "Successful closed seal phase required")
    require(index.get("created_after_raw_close") is True and index["files"]["seal.json"]["sha256"] == sha(path) and index["files"]["result.json"]["sha256"] == sha(path.parent / "result.json"), "Original seal/terminal index joins differ")
    seal = read(path)
    require(seal.get("sealed") is True and seal.get("source_phase") == str(path.parent), "Original successful seal identity required")
    return seal


def observe(raw, expected_commit):
    footer = re.findall(r"^Production A1-L3 focused transport registration: (\d+) checks, (\d+) failures; expected_commit=([0-9a-f]{40})\.(.+)$", raw, re.M)
    require(len(footer) == 1, "One actual existing registration footer required")
    checks, failed, commit, suffix = footer[0]
    expected = " Actual Full Title/Journey loading/one entrance dash/Save/NULL-Player Continue/earlier Retry/cleanup. TEST prefix2; zero Hero placements or public HP injuries. Later room optics/checkpoints/completion/contact/full route/human/mobile/performance remain separate untested behavior."
    require(commit == expected_commit and suffix == expected and int(checks) > 0, "Actual native footer identity/scope differs")
    return {"checks": int(checks), "failures": int(failed), "expected_commit": commit, "literal_footer": "Production A1-L3 focused transport registration: " + checks + " checks, " + failed + " failures; expected_commit=" + commit + "." + suffix, "structured_rows_present": False, "native_report_present": False, "native_completion_flag_present": False, "scope": "Existing actual footer only, joined to canonical return0; no synthetic rows/report/completion flag/full route credit."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("seal", "parse", "native"))
    parser.add_argument("--promotion", type=Path)
    parser.add_argument("--promotion-sha256")
    parser.add_argument("--seal", type=Path)
    args = parser.parse_args()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / ("run-" + args.phase + "-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    result = {"phase": args.phase, "closed": False, "passed": False, "engine_launch_attempted": False, "owned_validation_returned": False, "canonical_validation_return_code": None}
    queue = {"queued": False, "acquired": False}
    code, spec, sealed, promotion = 2, None, None, None
    save(out / "result.json", result)
    print("A1-L3 registration verification output:", out, flush=True)
    with (out / "raw.log").open("w") as log, contextlib.redirect_stdout(Tee(sys.stdout, log)), contextlib.redirect_stderr(Tee(sys.stderr, log)):
        try:
            require((args.phase == "seal") == (args.seal is None), "Only seal omits explicit successful --seal")
            if args.phase == "seal":
                require(args.promotion is not None and re.fullmatch(r"[0-9a-f]{64}", args.promotion_sha256 or "") is not None, "Seal requires exact Root --promotion and --promotion-sha256")
                selected = args.promotion.resolve()
                require(selected.is_file() and selected.is_relative_to(ROOT), "Root promotion receipt must exist in this checkout")
                promotion = {"path": str(selected.relative_to(ROOT)), "sha256": args.promotion_sha256}
            else:
                require(args.promotion is None and args.promotion_sha256 is None, "Engine phases reuse original seal promotion")
                selected = args.seal.resolve()
                prior = previous_seal(selected)
                sealed, promotion = prior["names"], prior["promotion"]
                save(out / "selected-seal.json", {"path": str(selected), "sha256": sha(selected)})
            spec = read(HERE / "INPUT_SPEC.json")
            current = snapshot(spec, out, "preflight-observed", promotion)
            prepared(spec, current, promotion)
            if args.phase == "seal":
                sealed = current
                save(out / "seal.json", {"sealed": True, "source_phase": str(out), "names": sealed, "promotion": promotion, "scope": spec["scope"]})
            else:
                require(current == sealed, "Current named inputs differ from explicit seal")
                module_spec = importlib.util.spec_from_file_location("cinder_a1_l3_verification_dev", ROOT / "scripts/dev/dev.py")
                require(module_spec is not None and module_spec.loader is not None, "Canonical dev module required")
                dev = importlib.util.module_from_spec(module_spec)
                sys.modules[module_spec.name] = dev
                old = sys.dont_write_bytecode
                try:
                    sys.dont_write_bytecode = True
                    module_spec.loader.exec_module(dev)
                finally:
                    sys.dont_write_bytecode = old
                context = dev.ProjectContext(root=ROOT, environ=dict(os.environ))
                command = [str(dev.resolve_godot(context)), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log")]
                if args.phase == "parse": command.append("--check-only")
                command += ["--script", "res://" + spec["selector"]]
                timeout = spec["timeout_seconds_after_lock"]
                require(type(timeout) is int and timeout == 180, "Frozen180s owned-child bound required")
                save(out / "command.json", {"argv": command, "timeout_seconds_after_lock": timeout, "queue_wait_in_watchdog": False, "environment_override": {}, "canonical_CLI_equivalent": "python3 scripts/dev/dev.py engine --headless --path . " + ("--check-only " if args.phase == "parse" else "") + "--script tests/act1_l3_registration_smoke.gd", "existing_registration_only": True})
                require(snapshot(spec, out, "sources-before-queue", promotion) == sealed, "Sources changed before queue")
                queue.update({"queued": True, "lock_path": str(dev.shared_lock_path(ROOT)), "queued_at": datetime.datetime.now(datetime.timezone.utc).isoformat()})
                save(out / "queue.json", queue)
                try:
                    with dev.godot_lock(ROOT) as lock_fd:
                        queue.update({"acquired": True, "acquired_at": datetime.datetime.now(datetime.timezone.utc).isoformat()})
                        save(out / "queue.json", queue)
                        require(snapshot(spec, out, "sources-at-lock", promotion) == sealed, "Sources changed at actual lock")
                        result["engine_launch_attempted"] = True
                        save(out / "result.json", result)
                        try:
                            returned = dev.run_validation(command, context, lock_fd, timeout, detect_godot_errors=True)
                            result.update({"owned_validation_returned": True, "canonical_validation_return_code": returned, "terminal_scope": "Canonical API return may be synthetic timeout/script failure; only canonical dev manages its direct child. CLOSED alone is not a separate OS exit claim."})
                            save(out / "result.json", result)
                        finally:
                            log.flush()
                            require(snapshot(spec, out, "sources-after-child", promotion) == sealed, "Sources changed after owned child operation")
                        if args.phase == "native":
                            observation = observe((out / "raw.log").read_text(), spec["expected_content_commit"])
                            save(out / "native-footer-observation.json", observation)
                            result["native_observation"] = observation
                            require(observation["failures"] == 0, "Actual native footer retains failures")
                        require(returned == 0, "Canonical owned validation must return zero")
                finally:
                    if queue["acquired"]:
                        queue.update({"lock_context_released": True, "released_at": datetime.datetime.now(datetime.timezone.utc).isoformat()})
                        save(out / "queue.json", queue)
            result["passed"], code = True, 0
        except KeyboardInterrupt:
            result["error"], code = "Interrupted; canonical dev owns direct-child cleanup", 130
        except Exception as error:
            result["error"] = str(error)
            print("A1-L3 registration verification failure:", error, flush=True)
        finally:
            if spec is not None and promotion is not None:
                try:
                    closed = snapshot(spec, out, "sources-at-runner-close", promotion)
                    require(sealed is None or closed == sealed, "Source drift at runner close")
                except Exception as error:
                    result["close_custody_error"] = str(error)
                    result["passed"], code = False, 2
            log.flush()
            result.update({"closed": True, "runner_return_code": code, "raw_diagnostic_lines": [line for line in (out / "raw.log").read_text().splitlines() if re.search(r"^\s*(?:ERROR|WARNING|SCRIPT ERROR):|ObjectDB.*leak|Orphan.*StringName", line, re.I)], "diagnostic_scope": "Actual host/runtime diagnostics retained separately; exit0 is not automatically clean."})
            save(out / "result.json", result)
            save(out / "queue.json", queue)
            print("A1-L3 registration verification CLOSED code=" + str(code), flush=True)
    save(out / "evidence-index.json", {"created_after_raw_close": True, "files": {str(p.relative_to(out)): {"sha256": sha(p), "bytes": p.stat().st_size} for p in sorted(out.rglob("*")) if p.is_file()}})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
