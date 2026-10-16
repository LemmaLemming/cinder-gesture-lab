"""UNEXECUTED private binding-tail differential. Root selects seal, then one pair.

Only Root may execute this prepared host. Both children use the same selected
leaf and canonical Script path. The subject is swapped/restored under the one
canonical Godot lock; no import, suite selection, worker or Store operation.
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
import signal
import stat
import sys
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
DIAGNOSTIC = re.compile(r"^\s*(?:ERROR|WARNING|SCRIPT ERROR):|ObjectDB.*leak|Orphan.*StringName", re.I)


def require(value, reason):
    if not value:
        raise ValueError(reason)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read(path):
    def pairs(values):
        result = {}
        for key, value in values:
            require(key not in result, "Duplicate JSON key: " + key)
            result[key] = value
        return result
    return json.loads(path.read_text(), object_pairs_hook=pairs,
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))


def save(path, value):
    data = (json.dumps(value, indent=2, allow_nan=False) + "\n").encode()
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("xb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def file_record(path):
    exists = os.path.lexists(path)
    status = path.lstat() if exists else None
    regular = bool(status and stat.S_ISREG(status.st_mode))
    data = path.read_bytes() if regular else None
    return {"exists": exists, "regular": regular,
            "symlink": bool(status and stat.S_ISLNK(status.st_mode)),
            "mode": format(stat.S_IMODE(status.st_mode), "04o") if status else None,
            "sha256": digest(data) if data is not None else None,
            "bytes": len(data) if data is not None else None}, data


def snapshot(spec, out, label, variant="original"):
    records, retained = {}, {}
    blobs = out / "source-blobs"
    blobs.mkdir(exist_ok=True)
    names = sorted(set(spec["expected"]) | set(spec["self_files"]))
    for name in names:
        record, data = file_record(ROOT / name)
        records[name] = record
        if data is not None:
            target = blobs / (record["sha256"] + ".bin")
            if not target.exists():
                with target.open("xb") as stream:
                    stream.write(data)
            require(digest(target.read_bytes()) == record["sha256"], "Retained CAS differs: " + name)
            retained[name] = dict(record, blob=str(target.relative_to(out)))
    save(out / (label + ".json"), {name: row["sha256"] for name, row in records.items()})
    save(out / (label + "-metadata.json"), records)
    save(out / (label + "-retention.json"), retained)
    expected = dict(spec["expected"])
    expected[spec["subject"]] = spec["subject_variants"][variant]["sha256"]
    for name, sha in expected.items():
        row = records[name]
        require(row["sha256"] == sha and row["mode"] == spec["expected_modes"][name], "Fixed bytes/mode differ: " + name)
        require((not row["exists"]) if sha is None else (row["regular"] and not row["symlink"]), "Fixed presence/type differs: " + name)
    readiness = read(HERE / "READINESS.json")
    for name in spec["self_files"]:
        row = records[name]
        require(row["regular"] and not row["symlink"] and row["mode"] == "0644", "Host control must be regular0644: " + name)
    for name, sha in readiness["frozen_files"].items():
        require(records[name]["sha256"] == sha, "Frozen host control differs: " + name)
    return records


def indexed(out):
    files = {}
    for path in sorted(out.rglob("*")):
        if path.is_file() and path != out / "evidence-index.json":
            files[str(path.relative_to(out))] = {"sha256": digest(path.read_bytes()), "bytes": path.stat().st_size,
                                                "mode": format(stat.S_IMODE(path.stat().st_mode), "04o")}
    save(out / "evidence-index.json", {"created_after_raw_close": True, "files": files})


class Tee:
    def __init__(self, first, second):
        self.first, self.second = first, second
    def write(self, value):
        self.second.write(value)
        return self.first.write(value)
    def flush(self):
        self.first.flush()
        self.second.flush()


def engine_record(path):
    record, _ = file_record(path)
    require(record["regular"] and not record["symlink"] and os.access(path, os.X_OK), "Resolved regular executable engine required")
    return dict(record, path=str(path), retained_binary=False,
                scope="Binary SHA/size/mode observed; executable not copied into source CAS")


def observe_native(out, raw, variant, subject_sha):
    path = out / "native-report.json"
    require(path.is_file(), "Actual native report absent; no reconstructed report")
    packet = read(path)
    require(packet.get("kind") == "authored-binding-tail-differential-1", "Wrong native kind")
    require(packet.get("variant") == variant and packet.get("source_sha256") == subject_sha, "Wrong actual canonical source/variant")
    rows = packet.get("rows")
    require(type(rows) is list and rows and type(packet.get("checks")) is int and packet["checks"] == len(rows), "Native rows/count mismatch")
    require(all(type(row) is dict and type(row.get("check")) is int and row["check"] == i and
                type(row.get("ok")) is bool and type(row.get("label")) is str and row["label"] and "note" in row
                for i, row in enumerate(rows, 1)), "Native consecutive typed rows required")
    failed = [row for row in rows if not row["ok"]]
    require(type(packet.get("failures")) is int and packet["failures"] == len(failed) and
            packet.get("first_failure") == (failed[0] if failed else {}), "Native first failure/count mismatch")
    require(type(packet.get("complete")) is bool and type(packet.get("success")) is bool and
            packet["success"] == (packet["complete"] and not failed), "Native completion/success mismatch")
    require(type(packet.get("observations")) is list and packet["observations"] and
            type(packet.get("initial_wire_exact")) is str and packet["initial_wire_exact"], "Actual semantic trace/initial wire required")
    footer = "BINDING TAIL DIFFERENTIAL: %d checks, %d failures; complete=%s" % (len(rows), len(failed), str(packet["complete"]).lower())
    require([line for line in raw.splitlines() if line.startswith("BINDING TAIL DIFFERENTIAL:")] == [footer], "Actual footer mismatch")
    printed = re.findall(r"^CINDER_BINDING_TAIL_REPORT=(.+) sha256=([0-9a-f]{64})$", raw, re.M)
    require(printed == [(str(path), digest(path.read_bytes()))], "Actual native report path/hash mismatch")
    joined = {"checks": len(rows), "failures": len(failed), "complete": packet["complete"],
              "success": packet["success"], "first_failure": packet["first_failure"],
              "report_sha256": digest(path.read_bytes()), "variant": variant, "source_sha256": subject_sha}
    save(out / "native-control-joins.json", joined)
    return packet, joined


def semantic_projection(packet):
    # Canonical JSON text preserves bool/int and int/float distinctions that
    # Python equality alone would collapse. Exact-wire strings stay opaque.
    return json.dumps({"observations": packet["observations"], "initial_wire_exact": packet["initial_wire_exact"]},
                      sort_keys=True, ensure_ascii=True, allow_nan=False, separators=(",", ":"))


def replace_subject(path, data, mode):
    temporary = path.with_name(path.name + ".binding-tail-owned-" + uuid.uuid4().hex + ".tmp")
    try:
        with temporary.open("xb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, int(mode, 8))
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def previous_seal(path):
    require(path.name == "seal.json" and path.parent.parent == HERE, "Explicit original seal from this host capsule required")
    result, index = read(path.parent / "result.json"), read(path.parent / "evidence-index.json")
    require(result.get("closed") is True and result.get("passed") is True and result.get("runner_return_code") == 0, "Closed successful seal required")
    for name in ["seal.json", "result.json"]:
        require(index["files"][name]["sha256"] == digest((path.parent / name).read_bytes()), "Seal/result index join differs")
    seal = read(path)
    require(seal.get("sealed") is True and seal.get("source_phase") == str(path.parent), "Seal identity differs")
    return seal


def execute_phase(dev, spec, pair_out, variant, context, engine, lock_fd):
    out = pair_out / variant
    out.mkdir(exist_ok=False)
    result = {"phase": variant, "closed": False, "passed": False, "native_functional_pass": False,
              "engine_launch_attempted": False, "owned_validation_returned": False,
              "canonical_validation_return_code": None, "independent_os_child_return_code": None,
              "terminal_scope": "Canonical run_validation API only; OS child status is not independently exposed. Timeout124/script1 may be synthetic. Canonical dev owns cleanup."}
    save(out / "result.json", result)
    packet, code, interrupted = None, 2, False
    with (out / "raw.log").open("x") as raw, contextlib.redirect_stdout(Tee(sys.stdout, raw)), contextlib.redirect_stderr(Tee(sys.stderr, raw)):
        try:
            snapshot(spec, out, "sources-at-lock", variant)
            before = engine_record(engine)
            save(out / "engine-before.json", before)
            require({key: before[key] for key in spec["engine_expected"]} == spec["engine_expected"], "Resolved engine pin differs")
            environ = dict(context.environ)
            environ["CINDER_BINDING_TAIL_VARIANT"] = variant
            environ["CINDER_BINDING_TAIL_REPORT"] = str(out / "native-report.json")
            native_context = dev.ProjectContext(root=ROOT, environ=environ)
            require(native_context.canonical_root == ROOT, "Native context canonical root differs")
            command = [str(engine), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log"), "--script", "res://" + spec["selected_fixture"]]
            save(out / "command.json", {"argv": command, "environment_override": {name: environ[name] for name in ["CINDER_BINDING_TAIL_VARIANT", "CINDER_BINDING_TAIL_REPORT"]},
                                        "canonical_api": "dev.godot_lock/run_validation", "timeout_seconds_after_lock": spec["timeout_after_lock_seconds"], "one_child": True})
            result["engine_launch_attempted"] = True
            save(out / "result.json", result)
            try:
                returned = dev.run_validation(command, native_context, lock_fd, spec["timeout_after_lock_seconds"], detect_godot_errors=True)
                result.update(owned_validation_returned=True, canonical_validation_return_code=returned)
            finally:
                raw.flush()
                snapshot(spec, out, "sources-after-child", variant)
                after = engine_record(engine)
                save(out / "engine-after.json", after)
                require(after == before, "Engine binary observation drift after child")
            raw.flush()
            packet, joined = observe_native(out, (out / "raw.log").read_text(), variant, spec["subject_variants"][variant]["sha256"])
            result["native_observation"] = joined
            require(packet["success"] and returned == 0, "Native functional/API phase failed; no same-phase rerun")
            result["native_functional_pass"] = True
            diagnostics = [line for line in (out / "raw.log").read_text().splitlines() if DIAGNOSTIC.search(line)]
            require(not diagnostics, "Raw diagnostic NONCLEAN; no diagnostic suppression or rerun")
            result["passed"], code = True, 0
        except KeyboardInterrupt:
            result["error"] = "Interrupted; canonical dev owns its direct child cleanup"
            code, interrupted = 130, True
        except Exception as error:
            result["error"] = str(error)
            print("Binding-tail phase failure:", error, flush=True)
        finally:
            raw.flush()
            path = out / "native-report.json"
            if path.is_file():
                save(out / "native-report-retention.json", {"sha256": digest(path.read_bytes()), "bytes": path.stat().st_size, "scope": "Original actual partial/complete native packet retained unchanged"})
            result.update(closed=True, runner_return_code=code,
                          raw_diagnostic_lines=[line for line in (out / "raw.log").read_text().splitlines() if DIAGNOSTIC.search(line)])
            save(out / "result.json", result)
    indexed(out)
    if interrupted:
        raise KeyboardInterrupt()
    return result, packet


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=["seal", "pair"])
    parser.add_argument("--seal", type=Path)
    args = parser.parse_args()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / ("run-" + args.phase + "-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    result = {"phase": args.phase, "closed": False, "passed": False, "candidate_accepted": False,
              "scope": "One declared actual canonical original/candidate binding-tail correctness differential only. No gameplay, acceptance or performance credit."}
    queue = {"queued": False, "acquired": False, "lock_context_released": False}
    code, spec, sealed = 2, None, None
    save(out / "result.json", result)
    # Cooperative interruption restores inside the lock. SIGKILL/power loss
    # cannot execute Python finally; durable original receipt enables Root recovery.
    old_term = signal.getsignal(signal.SIGTERM)
    signal.signal(signal.SIGTERM, lambda _sig, _frame: (_ for _ in ()).throw(KeyboardInterrupt()))
    with (out / "raw.log").open("x") as raw, contextlib.redirect_stdout(Tee(sys.stdout, raw)), contextlib.redirect_stderr(Tee(sys.stderr, raw)):
        try:
            require((args.phase == "seal") == (args.seal is None), "Pair requires explicit successful seal; seal takes none")
            spec = read(HERE / "INPUT_SPEC.json")
            require(spec["integration_root"] == str(ROOT) and HERE.parent == ROOT / ".cinder", "Exact flat canonical host required")
            require(spec["status"] == "READY_FOR_ROOT_SELECTION_UNEXECUTED", "Final producer/input readiness required")
            current = snapshot(spec, out, "preflight-observed")
            if args.phase == "seal":
                save(out / "seal.json", {"sealed": True, "source_phase": str(out), "records": current,
                                          "scope": result["scope"], "engine_expected": spec["engine_expected"]})
            else:
                selected = args.seal.resolve()
                sealed = previous_seal(selected)
                require(current == sealed["records"], "Sources differ from selected seal")
                save(out / "selected-seal.json", {"path": str(selected), "sha256": digest(selected.read_bytes())})
                module = importlib.util.spec_from_file_location("cinder_binding_tail_canonical_dev", ROOT / "scripts/dev/dev.py")
                require(module and module.loader, "Canonical dev loader required")
                dev = importlib.util.module_from_spec(module)
                sys.modules[module.name] = dev
                previous_bytecode = sys.dont_write_bytecode
                try:
                    sys.dont_write_bytecode = True
                    module.loader.exec_module(dev)
                finally:
                    sys.dont_write_bytecode = previous_bytecode
                context = dev.ProjectContext(root=ROOT, environ=dict(os.environ))
                require(context.canonical_root == ROOT, "Canonical root must remain Integration")
                engine = Path(dev.resolve_godot(context))
                require(snapshot(spec, out, "sources-before-queue") == sealed["records"], "Source drift before queue")
                queue.update(queued=True, lock_path=str(dev.shared_lock_path(ROOT)))
                save(out / "queue.json", queue)
                try:
                    with dev.godot_lock(ROOT) as lock_fd:
                        queue["acquired"] = True
                        save(out / "queue.json", queue)
                        require(snapshot(spec, out, "sources-at-lock") == sealed["records"], "Source drift at lock")
                        subject = ROOT / spec["subject"]
                        original_record, original = file_record(subject)
                        require(original_record["sha256"] == spec["subject_variants"]["original"]["sha256"], "Original subject identity differs")
                        backup = out / "subject-original.bin"
                        with backup.open("xb") as stream:
                            stream.write(original)
                            stream.flush()
                            os.fsync(stream.fileno())
                        save(out / "subject-original-custody.json", dict(original_record, path=spec["subject"], backup=str(backup), recovery="Root must hold canonical Godot lock before any recovery; never bypass or delete another lock"))
                        swapped = False
                        try:
                            old_result, old_packet = execute_phase(dev, spec, out, "original", context, engine, lock_fd)
                            # Preserve a warning-only Host2 honestly, while still
                            # allowing the one declared second functional cell.
                            require(old_result["native_functional_pass"], "Original functional cell failed; candidate remains unexecuted")
                            require(snapshot(spec, out, "sources-before-candidate-swap") == sealed["records"], "Drift before candidate swap")
                            candidate = (ROOT / spec["candidate_source"]).read_bytes()
                            require(digest(candidate) == spec["subject_variants"]["candidate"]["sha256"], "Candidate source drift")
                            swapped = True  # Set before replacement so any partial exception restores.
                            replace_subject(subject, candidate, original_record["mode"])
                            save(out / "swap-receipt.json", {"actual_canonical_script": spec["subject"], "original": original_record,
                                                              "candidate_sha256": digest(candidate), "under_canonical_lock": True})
                            snapshot(spec, out, "sources-after-candidate-swap", "candidate")
                            new_result, new_packet = execute_phase(dev, spec, out, "candidate", context, engine, lock_fd)
                            require(new_result["native_functional_pass"], "Candidate functional cell failed")
                            left, right = semantic_projection(old_packet), semantic_projection(new_packet)
                            comparison = {"equal": left == right, "original_projection_sha256": digest(left.encode()),
                                          "candidate_projection_sha256": digest(right.encode()), "keys": ["observations", "initial_wire_exact"],
                                          "excluded_report_metadata": ["variant", "source_sha256"], "ordered_observations": True,
                                          "candidate_accepted": False, "performance_claim": False}
                            save(out / "semantic-comparison.json", comparison)
                            require(comparison["equal"], "Actual semantic traces differ")
                            require(old_result["passed"] and new_result["passed"], "One or both functional cells NONCLEAN; comparison retained without clean success")
                        finally:
                            if swapped:
                                current_record, current_bytes = file_record(subject)
                                unexpected = current_record["sha256"] != spec["subject_variants"]["candidate"]["sha256"]
                                if unexpected:
                                    if current_bytes is not None:
                                        (out / "unexpected-subject-before-restore.bin").write_bytes(current_bytes)
                                    save(out / "unexpected-subject-before-restore.json", current_record)
                                replace_subject(subject, original, original_record["mode"])
                            restored, _ = file_record(subject)
                            save(out / "restore-receipt.json", {"restored_exact_bytes_and_mode": restored == original_record,
                                                                 "restored": restored, "swap_attempted": swapped, "under_canonical_lock": True})
                            require(restored == original_record, "Original subject restoration failed")
                            require(snapshot(spec, out, "sources-after-restore") == sealed["records"], "Source drift after original restoration")
                            require(not swapped or not unexpected, "Unexpected subject bytes preserved before owned original restoration")
                finally:
                    if queue["acquired"]:
                        queue["lock_context_released"] = True
                        save(out / "queue.json", queue)
            result["passed"], code = True, 0
        except KeyboardInterrupt:
            result["error"], code = "Interrupted; cooperative cleanup/restoration attempted inside canonical lock", 130
        except Exception as error:
            result["error"] = str(error)
            print("Binding-tail host failure:", error, flush=True)
        finally:
            if spec is not None:
                try:
                    closed = snapshot(spec, out, "sources-at-runner-close")
                    require(sealed is None or closed == sealed["records"], "Source drift at host close")
                except Exception as error:
                    result["close_custody_error"] = str(error)
                    result["passed"], code = False, 2
            if args.phase == "pair":
                result["cell_status"] = {}
                for variant in ["original", "candidate"]:
                    cell = out / variant / "result.json"
                    result["cell_status"][variant] = ({"status": "RECORDED_ACTUAL_HOST_PHASE", "result_sha256": digest(cell.read_bytes()),
                                                       "result": read(cell)} if cell.is_file() else {"status": "UNEXECUTED", "native_credit": False})
            raw.flush()
            result.update(closed=True, runner_return_code=code,
                          raw_diagnostic_lines=[line for line in (out / "raw.log").read_text().splitlines() if DIAGNOSTIC.search(line)])
            save(out / "result.json", result)
            save(out / "queue.json", queue)
            print("Binding-tail host CLOSED code=" + str(code), flush=True)
    signal.signal(signal.SIGTERM, old_term)
    indexed(out)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
