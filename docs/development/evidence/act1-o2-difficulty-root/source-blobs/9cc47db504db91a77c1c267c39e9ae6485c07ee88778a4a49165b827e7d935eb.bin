"""Private five-phase O2 verification: no promotion, import or suite expansion."""
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
ENV = "CINDER_A1_O2_SHORT_REGISTRATION_REPORT"


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


def function(text, name):
    match = re.search(r"^func " + re.escape(name) + r"\(", text, re.M)
    require(match is not None, "Missing Base function: " + name)
    following = re.search(r"^func ", text[match.end():], re.M)
    return text[match.start():match.end() + following.start() if following else len(text)].rstrip()


def prepared(spec, names, out):
    require(all(names.get(name) == digest for name, digest in spec["expected"].items()), "Fixed promoted source/config/UID differs")
    require(all(names.get(name) is not None for name in spec["self_files"]), "Runner capsule is incomplete")
    for name, digest in read(HERE / "READINESS.json")["frozen_files"].items():
        require(names[name] == digest, "Frozen runner capsule differs: " + name)
    promotion = read(ROOT / spec["promotion"]["path"])
    require(sha(ROOT / spec["promotion"]["path"]) == spec["promotion"]["sha256"] and len(promotion["cohort"]) == 28, "Exact Root promotion required")
    for row in promotion["cohort"]:
        path = ROOT / row["path"]
        require(names[row["path"]] == row["sha256"] and path.stat().st_size == row["bytes"] and not path.is_symlink() and not path.stat().st_mode & 0o111, "Promotion byte/size/mode differs: " + row["path"])
    before = (ROOT / spec["base_before_path"]).read_text()
    current = (ROOT / "scripts/acts/act1/mushroom_caverns.gd").read_text()
    membership = function(before, "current_source_ids") == function(current, "current_source_ids")
    physics = function(current, "_physics_process")
    substitution = "for id: String in admission_source_ids():"
    unchanged = physics.count(substitution) == 1 and physics.replace(substitution, "for id: String in current_source_ids():") == function(before, "_physics_process")
    save(out / "base-source-invariant.json", {"original_membership_function_exact": membership, "physics_exact_except_one_reviewed_hook_call": unchanged, "scope": "Static source identity; native behavior is the separate existing source-default case."})
    require(membership and unchanged, "Original Base membership/nonadmission physics changed")


def previous_seal(path):
    require(path.name == "seal.json" and path.parent.parent == HERE, "Explicit seal from this capsule required")
    result, index = read(path.parent / "result.json"), read(path.parent / "evidence-index.json")
    require(result.get("closed") is True and result.get("passed") is True and type(result.get("runner_return_code")) is int and result["runner_return_code"] == 0, "Seal phase did not close successfully")
    require(index.get("created_after_raw_close") is True and index["files"]["seal.json"]["sha256"] == sha(path) and index["files"]["result.json"]["sha256"] == sha(path.parent / "result.json"), "Seal/terminal result do not join original closed index")
    seal = read(path)
    require(seal.get("sealed") is True and seal.get("source_phase") == str(path.parent), "Actual original seal identity required")
    return seal["names"]


def dictionary_tag(value):
    require(isinstance(value, list) and len(value) == 2 and value[0] == "dictionary" and isinstance(value[1], list), "Exact dictionary tag required")
    require(all(isinstance(pair, list) and len(pair) == 2 and isinstance(pair[0], str) for pair in value[1]), "Exact dictionary entries required")
    answer = dict(value[1])
    require(len(answer) == len(value[1]), "Duplicate Exact dictionary key")
    return answer


def exact_tag(wire):
    require(isinstance(wire, str) and bool(wire), "Nonempty original native Exact string required")
    envelope = json.loads(wire)
    require(set(envelope) == {"api_revision", "schema_version", "value"} and envelope["api_revision"] == "exact-json-1" and type(envelope["schema_version"]) is int and envelope["schema_version"] == 1, "Original exact-json envelope required")
    return envelope["value"]


def native_string(value):
    require(isinstance(value, list) and len(value) == 2 and value[0] == "string" and isinstance(value[1], str), "Native Exact string tag required")
    return value[1]


def api2_receipts(report):
    """Inspect native-produced tags only; never decode/reencode a game packet."""
    receipts = report.get("exact_receipt_strings")
    require(isinstance(receipts, list) and len(receipts) == 1, "One actual fresh disk-Continue receipt required")
    row = dictionary_tag(exact_tag(receipts[0]))
    installed = exact_tag(native_string(row["exact_snapshot"]))
    attempts = exact_tag(native_string(row["exact_attempts"]))
    whole_story = exact_tag(native_string(row["exact_whole_protected_story"]))
    envelope_wire = native_string(row["saved_envelope_json"])
    disk = json.loads(envelope_wire)
    require(type(disk.get("format_version")) is int and disk["format_version"] == 2 and type(disk.get("generation")) is int and disk["generation"] > 0 and isinstance(disk.get("payload_json"), str), "Actual format2 disk envelope required")
    require(hashlib.sha256(disk["payload_json"].encode()).hexdigest() == disk.get("sha256"), "Original disk payload checksum differs")
    saved_attempts = exact_tag(disk["payload_json"])
    state = dictionary_tag(attempts)
    side = dictionary_tag(state["side_attempt"])
    require(saved_attempts == attempts and side["snapshot"] == installed and state["story"] == whole_story, "Whole saved/installed Attempts/snapshot/Story tags differ")
    snapshot = dictionary_tag(installed)
    level = dictionary_tag(snapshot["level"])
    local = dictionary_tag(level["local"])
    require(snapshot["level_id"] == ["string", "A1-O2"] and level["local_snapshot_version"] == ["integer", "1"], "Actual O2 local1 envelope required")
    require(len(local) == 15 and local["api_revision"] == ["string", "act1-spore-bloom-2"] and local["schema_version"] == ["integer", "2"] and local["world_revision"] == ["integer", "1"] and local["beat_index"] == ["integer", "0"] and local["room_stage"] == ["string", "approach"] and local["final_arrangement"] == ["dictionary", []], "Saved AND installed actual pristine API2/schema2/world1/empty recipe required")
    return {"actual_receipts": 1, "whole_disk_Attempts_installed_snapshot_Story_tags_equal": True, "local_api": "act1-spore-bloom-2", "schema_tag": local["schema_version"], "world_tag": local["world_revision"], "final_arrangement_tag": local["final_arrangement"], "native_snapshot_wire_sha256": hashlib.sha256(native_string(row["exact_snapshot"]).encode()).hexdigest(), "raw_disk_wire_sha256": hashlib.sha256(envelope_wire.encode()).hexdigest(), "scope": "Read-only original tagged JSON comparison, preserving float64/integer/string representations; no packet factory/native-validator claim."}


def observe(phase, out, raw, spec, names, prior_reports):
    if phase == "default":
        copies = []
        for path in sorted((ROOT / ".cinder").glob("a1-o2-difficulty-*-*.json")):
            if path.name not in prior_reports and path.is_file() and not path.is_symlink():
                target = out / ("generated-" + path.name)
                target.write_bytes(path.read_bytes())
                copies.append({"original_path": str(path), "sha256": sha(target), "retained_path": str(target)})
        save(out / "generated-native-reports.json", copies)
        footer = re.findall(r"^A1-O2 DIFFICULTY: (\d+) checks, (\d+) failures; complete=(true|false); report=(.+)$", raw, re.M)
        require(len(footer) == 1, "One actual default-case footer required")
        reported = footer[0][3]
        require(re.fullmatch(r"res://\.cinder/a1-o2-difficulty-\d+-\d+\.json", reported) is not None, "Actual fixed-prefix native report path required")
        original = ROOT / reported.removeprefix("res://")
        require(original.name not in prior_reports and any(row["original_path"] == str(original) for row in copies), "Native report must be newly generated under owned lock")
        native_path = out / "native-report.json"
        native_path.write_bytes(original.read_bytes())
    else:
        native_path = out / "native-report.json"
        footer = re.findall(r"^A1-O2 SHORT canonical registration: (\d+) checks/(\d+) failures; complete=(true|false); canonical entry/Save/disk Continue/entrance Retry/Leave only$", raw, re.M)
        require(native_path.is_file(), "Actual canonical native report required")
        printed = re.findall(r"^CINDER_A1_O2_SHORT_REGISTRATION_REPORT path=(.+) sha256=([0-9a-f]{64})$", raw, re.M)
        require(printed == [(str(native_path), sha(native_path))], "Actual canonical report path/SHA must join bytes")
    save(out / "native-report-retention.json", {"path": str(native_path), "sha256": sha(native_path), "bytes": native_path.stat().st_size, "scope": "Original native bytes retained before counter/row/packet checks."})
    report = read(native_path)
    rows = report.get("assertions" if phase == "default" else "rows")
    checks, failed = report.get("checks"), report.get("failures")
    key, ordinal = ("passed", "index") if phase == "default" else ("ok", "check")
    require(type(checks) is int and type(failed) is int and isinstance(rows, list) and all(isinstance(row, dict) and type(row.get(key)) is bool and type(row.get(ordinal)) is int for row in rows), "Actual strict counters/row types required")
    require(checks == len(rows) > 0 and [row[ordinal] for row in rows] == list(range(1, checks + 1)) and failed == sum(row[key] is False for row in rows) == 0 and report.get("first_failure") == {}, "Actual row/counter/failure joins differ")
    complete_key = "scope_complete" if phase == "default" else "complete"
    require(report.get(complete_key) is True and report.get("success") is True and len(footer) == 1 and footer[0][:3] == (str(checks), str(failed), "true"), "Actual completion/footer differs")
    if phase == "default":
        require(report.get("case") == "source-default" and report.get("requested_profile") == "standard", "Only existing source-default native case allowed")
        expected = {name: names[name] for name in spec["default_native_source_names"]}
        require(report.get("source_sha256") == expected, "Actual source-default source map differs")
    else:
        require(type(report.get("schema_version")) is int and report["schema_version"] == 1 and report.get("kind") == "a1-o2-short-canonical-registration", "Canonical actual report identity differs")
        expected = {"res://" + name: names[name] for name in spec["registration_native_source_names"]}
        require(report.get("source_observations_before") == report.get("source_observations_after") == expected, "Actual canonical source maps differ")
        save(out / "actual-api2-receipt-inspection.json", api2_receipts(report))
    return {"checks": checks, "failures": failed, complete_key: report[complete_key], "success": report["success"], "actual_rows": len(rows), "native_report_sha256": sha(native_path), "native_report_bytes": native_path.stat().st_size, "scope": "Actual selected native report; no synthetic assertion rows."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("seal", "parse", "default", "registration"))
    parser.add_argument("--target", choices=("default", "registration"))
    parser.add_argument("--seal", type=Path)
    args = parser.parse_args()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / ("run-" + args.phase + ("-" + args.target if args.target else "") + "-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    result = {"phase": args.phase, "target": args.target, "closed": False, "passed": False, "engine_launch_attempted": False, "owned_validation_returned": False, "canonical_validation_return_code": None}
    queue = {"queued": False, "acquired": False}
    code, spec, sealed = 2, None, None
    save(out / "result.json", result)
    print("O2 verification output:", out, flush=True)
    with (out / "raw.log").open("w") as log, contextlib.redirect_stdout(Tee(sys.stdout, log)), contextlib.redirect_stderr(Tee(sys.stderr, log)):
        try:
            require((args.phase == "parse") == (args.target is not None) and (args.phase == "seal") == (args.seal is None), "Only parse takes target; every engine phase requires explicit successful seal")
            spec = read(HERE / "INPUT_SPEC.json")
            current = snapshot(spec, out, "preflight-observed")
            prepared(spec, current, out)
            if args.phase == "seal":
                sealed = current
                save(out / "seal.json", {"sealed": True, "source_phase": str(out), "names": sealed, "scope": spec["scope"]})
            else:
                selected = args.seal.resolve()
                sealed = previous_seal(selected)
                require(current == sealed, "Current sources differ from explicit successful seal")
                save(out / "selected-seal.json", {"path": str(selected), "sha256": sha(selected)})
                module_spec = importlib.util.spec_from_file_location("cinder_o2_verification_dev", ROOT / "scripts/dev/dev.py")
                require(module_spec is not None and module_spec.loader is not None, "Canonical dev module required")
                dev = importlib.util.module_from_spec(module_spec)
                sys.modules[module_spec.name] = dev
                old_bytecode = sys.dont_write_bytecode
                try:
                    sys.dont_write_bytecode = True
                    module_spec.loader.exec_module(dev)
                finally:
                    sys.dont_write_bytecode = old_bytecode
                environ = {key: value for key, value in os.environ.items() if key != ENV}
                if args.phase == "registration": environ[ENV] = str(out / "native-report.json")
                context = dev.ProjectContext(root=ROOT, environ=environ)
                target = args.target if args.phase == "parse" else args.phase
                if target == "registration":
                    require(dev.SUITES.get(spec["existing_registration_alias"]) == spec["selectors"][target], "Existing dev alias differs")
                    paths = dev.suite_paths(context, spec["existing_registration_alias"])
                    require(paths == ["res://" + spec["selectors"][target]], "Existing canonical test resolves differently")
                command = [str(dev.resolve_godot(context)), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log")]
                if args.phase == "parse": command.append("--check-only")
                command += ["--script", "res://" + spec["selectors"][target]]
                if args.phase == "default": command += ["--", "--case=source-default"]
                timeout = spec["timeouts_after_lock_seconds"]["parse" if args.phase == "parse" else target]
                save(out / "command.json", {"argv": command, "timeout_seconds_after_lock": timeout, "environment_override": {ENV: environ[ENV]} if ENV in environ else {}, "canonical_CLI_equivalent": "python3 scripts/dev/dev.py test act1_o2_registration" if target == "registration" and args.phase != "parse" else None})
                require(snapshot(spec, out, "sources-before-queue") == sealed, "Sources changed before queue")
                queue.update({"queued": True, "lock_path": str(dev.shared_lock_path(ROOT))})
                save(out / "queue.json", queue)
                try:
                    with dev.godot_lock(ROOT) as lock_fd:
                        queue["acquired"] = True
                        save(out / "queue.json", queue)
                        require(snapshot(spec, out, "sources-at-lock") == sealed, "Sources changed at lock")
                        prior_reports = {path.name for path in (ROOT / ".cinder").glob("a1-o2-difficulty-*-*.json")} if args.phase == "default" else set()
                        save(out / "default-report-prefix-before-child.json", sorted(prior_reports))
                        result["engine_launch_attempted"] = True
                        save(out / "result.json", result)
                        returned = dev.run_validation(command, context, lock_fd, timeout, detect_godot_errors=True)
                        result.update({"owned_validation_returned": True, "canonical_validation_return_code": returned, "terminal_scope": "Canonical API return; may be synthetic timeout/script failure. Launch attempt/CLOSED alone do not prove OS child terminal. Only canonical dev manages its own direct child."})
                        save(out / "result.json", result)
                        log.flush()
                        after = snapshot(spec, out, "sources-after-child")
                        if args.phase in ("default", "registration"):
                            observation = observe(args.phase, out, (out / "raw.log").read_text(), spec, sealed, prior_reports)
                            save(out / "native-observation.json", observation)
                            result["native_observation"] = observation
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
            print("O2 verification failure:", error, flush=True)
        finally:
            if spec is not None:
                try:
                    closed = snapshot(spec, out, "sources-at-runner-close")
                    require(sealed is None or closed == sealed, "Source drift at runner close")
                except Exception as error:
                    result["close_custody_error"] = str(error)
                    result["passed"], code = False, 2
            log.flush()
            result.update({"closed": True, "runner_return_code": code, "raw_diagnostic_lines": [line for line in (out / "raw.log").read_text().splitlines() if re.search(r"^\s*(?:ERROR|WARNING|SCRIPT ERROR):|ObjectDB.*leak|Orphan.*StringName", line, re.I)], "diagnostic_scope": "Preserved actual diagnostics; zero return does not imply a clean host."})
            save(out / "result.json", result)
            save(out / "queue.json", queue)
            print("O2 verification CLOSED code=" + str(code), flush=True)
    save(out / "evidence-index.json", {"created_after_raw_close": True, "files": {str(path.relative_to(out)): {"sha256": sha(path), "bytes": path.stat().st_size} for path in sorted(out.rglob("*")) if path.is_file()}})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
