#!/usr/bin/env python3
"""OFFLINE future runner. Never execute without root's explicit adoption/release.

The native control writes the real canonical catalogue inside an actual source
getter. This finally restores the exact original bytes even on test/engine
failure. All other readers must be frozen for this narrowly owned interval.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import stat
import tempfile


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def restore_exact(path: Path, original: bytes, mode: int) -> None:
    if path.exists() and path.read_bytes() == original:
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
    if path.read_bytes() != original:
        raise RuntimeError("Original canonical catalogue byte restoration failed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute-reviewed-candidates", action="store_true")
    args = parser.parse_args()
    if not args.execute_reviewed_candidates:
        parser.error("Root must review/adopt the frozen candidates and authorize this exclusive mutation interval")
    directory = Path(__file__).resolve().parent
    root = directory.parent.parent
    manifest = json.loads((directory / "manifest.json").read_text())
    for relative, expected in manifest["artifacts"].items():
        data = (directory / relative).read_bytes()
        if len(data) != expected["bytes"] or digest(data) != expected["sha256"]:
            raise RuntimeError(f"Offline artifact differs from the reviewed release: {relative}")
    for relative, expected in manifest["fixture_dependencies"].items():
        if digest((root / relative).read_bytes()) != expected["sha256"]:
            raise RuntimeError(f"Actual fixture dependency changed; review a new receipt: {relative}")
    for relative, expected in manifest["candidates"].items():
        if digest((root / relative).read_bytes()) != expected["sha256"]:
            raise RuntimeError(f"Actual source differs from the reviewed candidate: {relative}")
    catalogue = root / "data/design/difficulty_profiles.json"
    original = catalogue.read_bytes()
    original_mode = stat.S_IMODE(catalogue.stat().st_mode)
    if digest(original) != manifest["catalogue_base"]["sha256"]:
        raise RuntimeError("Catalogue differs from the frozen original; review a new controlled receipt first")
    backup = directory / "future-original-catalogue.bin"
    backup.write_bytes(original)
    native = directory / "source-reuse-native.log"
    wrapper = directory / "source-reuse-wrapper.log"
    command = [
        "python3", "scripts/dev/dev.py", "engine", "--headless", "--verbose",
        "--path", str(root), "--script",
        "res://" + (directory / "source_reuse_smoke.gd").relative_to(root).as_posix(),
        "--log-file", str(native), "--", "--allow-canonical-catalogue-mutation",
    ]
    try:
        with wrapper.open("wb") as output:
            return subprocess.run(command, cwd=root, stdout=output, stderr=subprocess.STDOUT, check=False).returncode
    finally:
        restore_exact(catalogue, original, original_mode)
        print(f"Exact original catalogue restored: {digest(catalogue.read_bytes())}")


if __name__ == "__main__":
    raise SystemExit(main())
