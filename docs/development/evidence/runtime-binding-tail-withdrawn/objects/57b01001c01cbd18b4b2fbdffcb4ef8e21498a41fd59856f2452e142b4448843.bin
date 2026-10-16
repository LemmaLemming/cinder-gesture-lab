"""UNEXECUTED private binding-tail cost pair. Root selects seal, then one pair.

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
import cost_metrics

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
    payload = cost_metrics.extract_profile(raw)
    path = out / "native-profile.json"
    with path.open("xb") as stream:
        stream.write(payload.encode())
    save(out / "native-profile-extraction.json", {"source": "raw.log single AUTHORED_ECHO_PROFILE_JSON line", "sha256": digest(path.read_bytes()), "bytes": path.stat().st_size, "native_produced_file": False, "scope": "Exact original JSON payload extracted without reserialization; raw stream remains primary"})
    packet, joined = cost_metrics.validate_profile(raw, payload)
    joined.update(variant=variant, source_sha256=subject_sha, profile_sha256=digest(path.read_bytes()))
    save(out / "native-control-joins.json", joined)
    return packet, joined


def semantic_projection(packet):
    return cost_metrics.semantic_projection(packet)


def replace_subject(path, data, mode, expected_prior):
    require(expected_prior["regular"] and not expected_prior["symlink"], "Expected prior subject must be a regular non-symlink")
    temporary = path.with_name(path.name + ".binding-tail-owned-" + uuid.uuid4().hex + ".tmp")
    try:
        with temporary.open("xb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, int(mode, 8))
        # Recheck exact prior bytes/size/mode/type AFTER the replacement is ready,
        # immediately before replace, for both selection and restoration. The
        # cooperating canonical lock cannot remove an uncooperative OS TOCTOU.
        require(file_record(path)[0] == expected_prior, "Subject prior bytes/size/mode/type changed; left in situ")
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def retain_unexpected_subject(path, out, label):
    record, data = file_record(path)
    if data is not None:
        with (out / (label + ".bin")).open("xb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
    metadata = dict(record, subject=str(path), left_in_situ=True)
    if record["symlink"]:
        metadata["link_target"] = os.readlink(path)  # Never read the foreign target.
    save(out / (label + ".json"), metadata)
    return record


def restore_subject_if_known(path, original, original_record, candidate_record, out,
                             owned_children_closed, swap_attempted):
    receipt = {"restored_exact_bytes_and_mode": False, "swap_attempted": swap_attempted,
               "under_canonical_lock": True, "owned_children_closed": owned_children_closed,
               "subject_write_attempted": False, "unknown_subject_overwrite_authorized": False}
    if not owned_children_closed:
        receipt.update(status="FAILED_OWNED_CHILD_STILL_OPEN_NO_WRITE", restored=file_record(path)[0])
    else:
        current = file_record(path)[0]
        if current == original_record:
            # Covers an interruption before atomic swap; do not misclassify an
            # unchanged original as a foreign edit or rewrite it needlessly.
            receipt.update(status="ALREADY_EXACT_ORIGINAL_NO_WRITE", restored=current,
                           restored_exact_bytes_and_mode=True)
        elif current == candidate_record:
            receipt["subject_write_attempted"] = True
            try:
                replace_subject(path, original, original_record["mode"], candidate_record)
                restored = file_record(path)[0]
                receipt.update(status="RESTORED_KNOWN_CANDIDATE" if restored == original_record else "FAILED_POST_RESTORE_DRIFT",
                               restored=restored, restored_exact_bytes_and_mode=restored == original_record)
                if restored != original_record:
                    retain_unexpected_subject(path, out, "unexpected-subject-after-restore")
            except Exception as error:
                # A final-guard conflict is left untouched, including mode/type.
                receipt.update(status="FAILED_GUARDED_RESTORE_NO_UNKNOWN_WRITE", error=str(error),
                               restored=retain_unexpected_subject(path, out, "unexpected-subject-at-restore-guard"))
        else:
            receipt.update(status="FAILED_UNKNOWN_SUBJECT_LEFT_IN_SITU",
                           restored=retain_unexpected_subject(path, out, "unexpected-subject-before-restore"))
    save(out / "restore-receipt.json", receipt)
    return receipt


def previous_seal(path):
    require(path.name == "seal.json" and path.parent.parent == HERE, "Explicit original seal from this host capsule required")
    result, index = read(path.parent / "result.json"), read(path.parent / "evidence-index.json")
    require(result.get("closed") is True and result.get("passed") is True and result.get("runner_return_code") == 0, "Closed successful seal required")
    for name in ["seal.json", "result.json"]:
        require(index["files"][name]["sha256"] == digest((path.parent / name).read_bytes()), "Seal/result index join differs")
    seal = read(path)
    require(seal.get("sealed") is True and seal.get("source_phase") == str(path.parent), "Seal identity differs")
    return seal


def execute_phase(dev, spec, pair_out, variant, context, engine, lock_fd, owned_registry=None):
    out = pair_out / variant
    out.mkdir(exist_ok=False)
    result = {"phase": variant, "closed": False, "passed": False, "native_functional_pass": False,
              "engine_launch_attempted": False, "owned_validation_returned": False,
              "canonical_validation_return_code": None, "owned_popen_children": [],
              "terminal_scope": "Canonical API return and the same actual owned Popen object's wait/poll status are recorded separately; this is not a second independent external OS terminal receipt. Timeout124/script1 may be synthetic. Canonical dev owns its one direct child."}
    save(out / "result.json", result)
    packet, code, interrupted = None, 2, False
    with (out / "raw.log").open("x") as raw, contextlib.redirect_stdout(Tee(sys.stdout, raw)), contextlib.redirect_stderr(Tee(sys.stderr, raw)):
        try:
            snapshot(spec, out, "sources-at-lock", variant)
            before = engine_record(engine)
            save(out / "engine-before.json", before)
            require({key: before[key] for key in spec["engine_expected"]} == spec["engine_expected"], "Resolved engine pin differs")
            environ = dict(context.environ)
            native_context = dev.ProjectContext(root=ROOT, environ=environ)
            require(native_context.canonical_root == ROOT, "Native context canonical root differs")
            command = [str(engine), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log"), "--script", "res://" + spec["selected_fixture"]]
            save(out / "command.json", {"argv": command, "environment_override": {}, "selection_metadata_only": variant,
                                        "canonical_api": "dev.godot_lock/run_validation", "timeout_seconds_after_lock": spec["timeout_after_lock_seconds"], "one_child": True})
            result["engine_launch_attempted"] = True
            save(out / "result.json", result)
            owned, actual_popen = [], dev.subprocess.Popen
            def tracked_popen(*arguments, **keywords):
                require(not owned, "Exactly one owned canonical child per cell")
                require(arguments and arguments[0] == command and keywords.get("cwd") == ROOT and
                        keywords.get("env") == native_context.environ and keywords.get("pass_fds") == (lock_fd,), "Actual canonical child command/context/lock differs")
                child = actual_popen(*arguments, **keywords)
                owned.append(child)
                if owned_registry is not None:
                    owned_registry.append(child)
                return child
            try:
                dev.subprocess.Popen = tracked_popen
                try:
                    returned = dev.run_validation(command, native_context, lock_fd, spec["timeout_after_lock_seconds"], detect_godot_errors=True)
                    result.update(owned_validation_returned=True, canonical_validation_return_code=returned)
                finally:
                    dev.subprocess.Popen = actual_popen
                    for child in owned:
                        if child.poll() is None:
                            dev.stop_validation(child)  # Only this cell's actual owned child.
                        child.wait(timeout=5)
                    result["owned_popen_children"] = [{"pid": child.pid, "closed": child.poll() is not None, "popen_return_code": child.poll()} for child in owned]
            finally:
                dev.subprocess.Popen = actual_popen
                raw.flush()
                snapshot(spec, out, "sources-after-child", variant)
                after = engine_record(engine)
                save(out / "engine-after.json", after)
                require(after == before, "Engine binary observation drift after child")
            raw.flush()
            packet, joined = observe_native(out, (out / "raw.log").read_text(), variant, spec["subject_variants"][variant]["sha256"])
            result["native_observation"] = joined
            require(len(owned) == 1 and owned[0].poll() == 0, "Actual owned Popen child must close0")
            require(joined["functional_complete"] and returned == 0, "Native functional/API phase failed; no same-phase rerun")
            result["native_functional_pass"] = True
            diagnostics = [line for line in (out / "raw.log").read_text().splitlines() if DIAGNOSTIC.search(line)]
            require(not diagnostics, "Raw diagnostic NONCLEAN; no diagnostic suppression or rerun")
            result["passed"], code = True, 0
        except KeyboardInterrupt:
            result["error"] = "Interrupted; canonical dev owns its direct child cleanup"
            code, interrupted = 130, True
        except Exception as error:
            result["error"] = str(error)
            print("Binding-tail cost phase failure:", error, flush=True)
        finally:
            raw.flush()
            path = out / "native-profile.json"
            if path.is_file():
                save(out / "native-profile-retention.json", {"sha256": digest(path.read_bytes()), "bytes": path.stat().st_size, "scope": "Original extracted actual profile payload retained unchanged; raw log also retains partial/missing evidence"})
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
              "scope": "One unchanged113 original-first/candidate-second native cost pair. Descriptive inclusive wall timings only; no CPU/FPS/acceptance or causal gain claim."}
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
                        owned_children = []
                        candidate_record = dict(original_record, sha256=spec["subject_variants"]["candidate"]["sha256"],
                                                bytes=(ROOT / spec["candidate_source"]).stat().st_size)
                        try:
                            old_result, old_packet = execute_phase(dev, spec, out, "original", context, engine, lock_fd, owned_children)
                            # Preserve a warning-only Host2 honestly, while still
                            # allowing the one declared second functional cell.
                            require(old_result["native_functional_pass"], "Original functional cell failed; candidate remains unexecuted")
                            require(snapshot(spec, out, "sources-before-candidate-swap") == sealed["records"], "Drift before candidate swap")
                            candidate = (ROOT / spec["candidate_source"]).read_bytes()
                            require(digest(candidate) == spec["subject_variants"]["candidate"]["sha256"], "Candidate source drift")
                            swapped = True  # Set before replacement so any partial exception restores.
                            replace_subject(subject, candidate, original_record["mode"], original_record)
                            save(out / "swap-receipt.json", {"actual_canonical_script": spec["subject"], "original": original_record,
                                                              "candidate_sha256": digest(candidate), "under_canonical_lock": True})
                            snapshot(spec, out, "sources-after-candidate-swap", "candidate")
                            new_result, new_packet = execute_phase(dev, spec, out, "candidate", context, engine, lock_fd, owned_children)
                            require(new_result["native_functional_pass"], "Candidate functional cell failed")
                            left, right = semantic_projection(old_packet), semantic_projection(new_packet)
                            comparison = {"equal": left == right, "original_projection_sha256": digest(left.encode()),
                                          "candidate_projection_sha256": digest(right.encode()), "keys": cost_metrics.SEMANTIC_KEYS,
                                          "excluded_report_metadata": ["absolute timing/frame counters and timing summaries"], "ordered_native_workload": True,
                                          "candidate_accepted": False, "performance_claim": False}
                            save(out / "semantic-comparison.json", comparison)
                            require(comparison["equal"], "Actual semantic traces differ")
                            save(out / "cost-comparison.json", cost_metrics.comparison(old_packet, new_packet))
                            require(old_result["passed"] and new_result["passed"], "One or both functional cells NONCLEAN; comparison retained without clean success")
                        finally:
                            receipt = restore_subject_if_known(subject, original, original_record, candidate_record, out,
                                                               all(child.poll() is not None for child in owned_children), swapped)
                            require(snapshot(spec, out, "sources-after-restore") == sealed["records"], "Source drift after original restoration")
                            require(receipt["restored_exact_bytes_and_mode"], "Original restoration refused/failed: " + receipt["status"])
                finally:
                    if queue["acquired"]:
                        queue["lock_context_released"] = True
                        save(out / "queue.json", queue)
            result["passed"], code = True, 0
        except KeyboardInterrupt:
            result["error"], code = "Interrupted; cooperative cleanup/restoration attempted inside canonical lock", 130
        except Exception as error:
            result["error"] = str(error)
            print("Binding-tail cost host failure:", error, flush=True)
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
            print("Binding-tail cost host CLOSED code=" + str(code), flush=True)
    signal.signal(signal.SIGTERM, old_term)
    indexed(out)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
