#!/usr/bin/env python3
"""Future authorized native control through actual dev.main's existing lock.

No engine is started by importing this file. Review/adoption and permission are
external requirements. This runner never acquires a second Godot lock or starts
a child dev CLI. Its in-memory run_child wrapper restores BEFORE dev.main exits
the canonical godot_lock context. Hard termination cannot guarantee cleanup.
"""
from __future__ import annotations

import argparse
import contextlib
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import signal
import stat
import sys
import tempfile
import traceback


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def checked_file(path: Path, record: dict) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f"Frozen original missing/linked: {path}")
    raw = path.read_bytes()
    if len(raw) != record["bytes"] or digest(raw) != record["sha256"]:
        raise RuntimeError(f"Frozen original changed: {path}")
    return raw


def verify_release(directory: Path, root: Path, manifest: dict) -> None:
    for relative, record in manifest["artifacts"].items():
        checked_file(directory / relative, record)
    for relative, record in manifest["fixture_dependencies"].items():
        checked_file(root / relative, record)
    for relative, record in manifest["candidates"].items():
        checked_file(root / relative, record)
    prior = manifest["prior_release"]
    prior_path = root / prior["manifest_path"]
    prior_value = json.loads(checked_file(prior_path, prior))
    for relative, record in prior_value["artifacts"].items():
        checked_file(prior_path.parent / relative, record)


def restore_exact(path: Path, original: bytes, mode: int) -> None:
    if (path.is_file() and not path.is_symlink() and path.read_bytes() == original and
            stat.S_IMODE(path.stat().st_mode) == mode):
        return
    fd, name = tempfile.mkstemp(prefix=".source-reuse-restore-", dir=path.parent)
    try:
        os.fchmod(fd, mode)
        with os.fdopen(fd, "wb") as stream:
            stream.write(original)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)
    if path.read_bytes() != original or stat.S_IMODE(path.stat().st_mode) != mode:
        raise RuntimeError("Original catalogue byte/mode restoration failed")


@contextlib.contextmanager
def redirected_native_output(path: Path):
    # Python redirect_stdout alone does not capture the actual inherited native fds.
    sys.stdout.flush()
    sys.stderr.flush()
    saved = (os.dup(1), os.dup(2))
    try:
        with path.open("xb") as output:
            os.dup2(output.fileno(), 1)
            os.dup2(output.fileno(), 2)
            yield
            sys.stdout.flush()
            sys.stderr.flush()
    finally:
        os.dup2(saved[0], 1)
        os.dup2(saved[1], 2)
        os.close(saved[0])
        os.close(saved[1])


def load_actual_dev(root: Path, expected: dict):
    path = root / "scripts/dev/dev.py"
    checked_file(path, expected)
    spec = importlib.util.spec_from_file_location("cinder_source_reuse_actual_dev", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("Actual canonical dev module cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    previous = sys.dont_write_bytecode
    sys.dont_write_bytecode = True
    try:
        spec.loader.exec_module(module)
    finally:
        sys.dont_write_bytecode = previous
    if module.ROOT != root or not callable(module.main) or not callable(module.run_child):
        raise RuntimeError("Actual canonical dev API/root differs")
    return module


def invoke_locked(dev, argv: list[str], directory: Path, root: Path,
                  manifest: dict, receipt: dict) -> int:
    """Wrap exactly one actual run_child, whose caller owns godot_lock already."""
    actual_run_child = dev.run_child
    catalogue = root / manifest["catalogue_base"]["path"]

    def guarded_run_child(command, context, lock_fd=None):
        if receipt["lock_entered"] or lock_fd is None or context.root != root:
            raise RuntimeError("Exactly one canonical locked native engine child required")
        os.fstat(lock_fd)  # Live borrowed descriptor; do not flock/unlock/reacquire it.
        receipt["lock_entered"] = True
        receipt["locked_at"] = now()
        receipt["actual_native_argv"] = list(command)
        receipt["borrowed_lock_fd"] = lock_fd
        original = None
        original_mode = None
        owned_children = []
        pending_signals = []
        actual_popen = dev.subprocess.Popen
        previous_handlers = {value: signal.getsignal(value) for value in (signal.SIGINT, signal.SIGTERM)}

        def defer_shutdown(value, _frame):
            # Let the original child finish/close before restoration; do not
            # unwind the wrapper and leave a live native writer behind.
            if len(pending_signals) < 16:
                pending_signals.append(value)

        def observe_actual_popen(*args, **kwargs):
            child = actual_popen(*args, **kwargs)
            owned_children.append(child)
            return child

        try:
            for value in previous_handlers:
                signal.signal(value, defer_shutdown)
            # Recheck after the queue wait, under the existing canonical lock.
            verify_release(directory, root, manifest)
            original = checked_file(catalogue, manifest["catalogue_base"])
            original_mode = stat.S_IMODE(catalogue.stat().st_mode)
            (directory / "original-catalogue.bin").write_bytes(original)
            receipt["original_catalogue"] = {"sha256": digest(original), "bytes": len(original),
                                               "mode": original_mode, "captured_under_lock": True}
            # Capture only the child the ORIGINAL run_child creates. No second
            # process or altered native argv/env/pass_fds/working dir is used.
            dev.subprocess.Popen = observe_actual_popen
            receipt["child_started_at"] = now()
            result = actual_run_child(command, context, lock_fd)
            receipt["actual_child_exit"] = result
        finally:
            dev.subprocess.Popen = actual_popen
            try:
                # If wait raised unexpectedly, do not restore while that same
                # owned native child can still write. No force kill is issued.
                for child in owned_children:
                    while child.poll() is None:
                        try:
                            child.wait()
                        except KeyboardInterrupt:
                            if len(pending_signals) < 16:
                                pending_signals.append(signal.SIGINT)
                    receipt["actual_child_exit"] = child.returncode
                    receipt["actual_child_pid"] = child.pid
                receipt["child_closed_at"] = now() if owned_children else None
                if original is not None:
                    restore_exact(catalogue, original, original_mode)
                    receipt["restored_catalogue"] = {"sha256": digest(catalogue.read_bytes()),
                                                       "bytes": len(original),
                                                       "mode": stat.S_IMODE(catalogue.stat().st_mode),
                                                       "restored_at": now(), "while_canonical_lock_held": True}
                    os.fstat(lock_fd)
                    print("SOURCE_REUSE_CATALOGUE_RESTORED_UNDER_CANONICAL_LOCK " + digest(original), flush=True)
            finally:
                receipt["deferred_shutdown_signals"] = pending_signals
                for value, handler in previous_handlers.items():
                    signal.signal(value, handler)
        if pending_signals:
            return 128 + pending_signals[0]
        return result

    dev.run_child = guarded_run_child
    try:
        return dev.main(argv)
    finally:
        dev.run_child = actual_run_child


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute-reviewed-candidates", action="store_true")
    parser.add_argument("--run-id", default="source-reuse-control1",
                        help="Plain canonical original job ID; existing logs/receipts are never overwritten")
    args = parser.parse_args()
    if not args.execute_reviewed_candidates:
        parser.error("Root must adopt/review this release and authorize its native catalogue-write interval")
    directory = Path(__file__).resolve().parent
    root = directory.parent.parent
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,95}", args.run_id):
        parser.error("Run ID must be a plain lowercase canonical job name")
    manifest_raw = (directory / "manifest.json").read_bytes()
    manifest = json.loads(manifest_raw)
    verify_release(directory, root, manifest)
    native = root / ".cinder" / (args.run_id + ".log")
    wrapper = root / ".cinder" / (args.run_id + "-wrapper.log")
    if (native.exists() or wrapper.exists() or
            any((directory / name).exists() for name in ("submission.json", "closure.json", "original-catalogue.bin"))):
        raise RuntimeError("Original submission/output already exists; create a separate reviewed run release")
    argv = ["engine", "--headless", "--verbose", "--path", str(root), "--script",
            "res://" + (directory / "source_reuse_smoke.gd").relative_to(root).as_posix(),
            "--log-file", str(native), "--", "--allow-canonical-catalogue-mutation"]
    receipt = {"api_revision": "test-only-source-reuse-submission-1", "run_id": args.run_id, "submitted_at": now(),
               "release_manifest_sha256": digest(manifest_raw), "runner_pid": os.getpid(),
               "actual_runner_argv": sys.argv[:], "canonical_dev_main_argv": argv,
               "actual_native_argv": None, "lock_entered": False,
               "permission_provenance": None, "tool_session": None,
               "provenance_limit": "Actual local argv only; approval/session provenance is not manufactured",
               "cleanup_limit": "Catchable shutdown waits for the original child; SIGKILL/process or machine loss can prevent finally"}
    (directory / "submission.json").write_text(json.dumps(receipt, indent=2) + "\n")
    result = None
    error = None
    try:
        with redirected_native_output(wrapper):
            try:
                dev = load_actual_dev(root, manifest["fixture_dependencies"]["scripts/dev/dev.py"])
                result = invoke_locked(dev, argv, directory, root, manifest, receipt)
                if type(result) is not int:
                    raise RuntimeError("Actual dev.main returned no integer exit")
            except BaseException:
                # Keep runner/bootstrap/cleanup failures in the full wrapper
                # log as well as its explicit closure, even if child exit was 0.
                traceback.print_exc()
                raise
        return result
    except BaseException as exc:
        error = type(exc).__name__ + ": " + str(exc)
        raise
    finally:
        receipt["closed_at"] = now()
        receipt["dev_main_exit"] = result
        receipt["exception"] = error
        receipt["logs"] = [{"path": path.relative_to(root).as_posix(), "bytes": len(path.read_bytes()),
                            "sha256": digest(path.read_bytes())} for path in (native, wrapper) if path.is_file()]
        receipt["scope"] = "Actual future source-reuse control; classify full logs independently, never infer native pass from dev exit"
        (directory / "closure.json").write_text(json.dumps(receipt, indent=2) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
