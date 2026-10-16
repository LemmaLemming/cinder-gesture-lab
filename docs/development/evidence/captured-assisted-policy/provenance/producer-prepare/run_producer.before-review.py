"""INERT PREPARED runner: Root alone promotes/seals/runs via canonical queue."""
from pathlib import Path
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
SCRIPT = str((HERE / "producer.gd").relative_to(ROOT))
SHIM = str((HERE / "profile_main.gd").relative_to(ROOT))
RUNNER = str(Path(__file__).resolve().relative_to(ROOT))
MANIFEST = str((HERE / "source-inputs.json").relative_to(ROOT))
FILES = (
    SCRIPT, SHIM, RUNNER, MANIFEST,
    SCRIPT + ".txt", SHIM + ".txt",
    'data/campaign/act3/crystalman_layout.json',
    'data/design/difficulty_profiles.json',
    'docs/DIFFICULTY_DESIGN.md',
    'project.godot',
    'scenes/main.tscn',
    'scenes/player.tscn',
    'scripts/acts/act3/crystalman_capture_codec.gd',
    'scripts/acts/act3/crystalman_capture_phase.gd',
    'scripts/acts/act3/crystalman_level.gd',
    'scripts/acts/act3/crystalman_parent_codec.gd',
    'scripts/acts/act3/crystalman_phase_policy.gd',
    'scripts/acts/act3/crystalman_recorded_frame_art.gd',
    'scripts/acts/act3/crystalman_scenery.gd',
    'scripts/campaign/exact_json.gd',
    'scripts/campaign/level.gd',
    'scripts/campaign/save_store.gd',
    'scripts/campaign/shell.gd',
    'scripts/campaign/snapshot_codec.gd',
    'scripts/combat/action_capture.gd',
    'scripts/combat/authored_enemy_sequence.gd',
    'scripts/combat/difficulty.gd',
    'scripts/combat/replay_capture_gate.gd',
    'scripts/combat/replay_cursor.gd',
    'scripts/combat/replay_footprint.gd',
    'scripts/combat/replay_playback.gd',
    'scripts/combat/replay_program.gd',
    'scripts/combat/replay_sequence.gd',
    'scripts/combat/replay_witness.gd',
    'scripts/combat/threat_scheduler.gd',
    'scripts/dev/dev.py',
    'scripts/equipment.gd',
    'scripts/game.gd',
    'scripts/player.gd',
    'tests/acts/act3/crystalman_parent_phase_smoke.gd',
    'tests/acts/act3/crystalman_parent_transport_smoke.gd',
    'tests/acts/act3/crystalman_rule_room_smoke.gd',
    'tests/acts/act3/crystalman_two_slot_rule_room_smoke.gd',
    'tests/acts/act3/fixtures/crystalman_declared_2.tscn',
    'tests/acts/act3/fixtures/crystalman_declared_parent.gd',
    'tests/authored_echo_playback_smoke.gd',
    'tests/replay_playback_smoke.gd',
    'tests/replay_scheduler_smoke.gd',
    'tests/threat_scheduler_smoke.gd',
)
NAMES = tuple(sorted(set(FILES) | {name + ".uid" for name in FILES if name.endswith(".gd")}))
TIMEOUT = 180


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot():
    return {name: sha(ROOT / name) if (ROOT / name).is_file() else None for name in NAMES}


def check_sources(original, current):
    for name, expected in original.items():
        if current.get(name) != expected:
            raise ValueError("Fixed named source/UID drift: " + name)


class Tee:
    def __init__(self, original, log):
        self.original, self.log = original, log
    def write(self, value):
        self.log.write(value)
        return self.original.write(value)
    def flush(self):
        self.log.flush(); self.original.flush()


def main():
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    out = HERE / ("native-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    def save(name, value):
        (out / name).write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")
    pinned = json.loads((HERE / "source-inputs.json").read_text())
    for row in pinned["files"]:
        path = ROOT / row["path"]
        if not path.is_file() or path.stat().st_size != row["size"] or sha(path) != row["sha256"]:
            raise ValueError("Prepared original-policy named pin changed; do not run after policy migration: " + row["path"])
    for name in (SCRIPT, SHIM):
        if not (ROOT / name).is_file() or (ROOT / name).read_bytes() != (ROOT / (name + ".txt")).read_bytes():
            raise ValueError("Root must promote exact prepared private text before running: " + name)
    sealed = snapshot()
    if any(sealed[name] is None for name in FILES):
        raise ValueError("Every explicitly named producer input must exist")
    missing = [name for name, value in sealed.items() if value is None]
    if set(missing) - {SCRIPT + ".uid", SHIM + ".uid"}:
        raise ValueError("Only the two private caller UID sidecars may be absent")
    parent = (ROOT / "scripts/acts/act3/crystalman_capture_phase.gd").read_text()
    codec = (ROOT / 'scripts/acts/act3/crystalman_capture_codec.gd').read_text()
    if 'const API: String = "act3-crystalman-captured-phase-2"' not in codec or 'func _authored() -> Dictionary:' not in parent:
        raise ValueError("Refuse migrated captured phase codec; Root must independently compare exact audit pins before this run")
    save("sealed-inputs.json", {"sealed": True, "sealed_by": "/root/act1_o2_registration_prepare", "created_at": now(), "root": str(ROOT), "names": sealed, "scope": "Fixed named source/UID observations only; no recursive graph/global UID/frozen bank census. Registry and A3-O3 metadata are deliberately unused/unpinned. Two private UID sidecars remain absent; no editor import is launched."})
    result = {"kind": "new-original-captured-api2-producer-execution", "started_at": now(), "output": str(out), "closed": False, "engine_started": False, "owned_child_terminal": False, "engine_return_code": None, "passed": False, "scope": "New old captured API2 complete Player+phase/Store, declared TEST prior history, no historical/CampaignAttempts/whole-parent optical credit."}
    queue = {"queued": False, "acquired": False, "timeout_seconds_after_acquisition": TIMEOUT}
    save("result.json", result); save("queue.json", queue)
    code = 2
    print("Original captured producer output:", out, flush=True)
    with (out / "raw.log").open("w") as log, contextlib.redirect_stdout(Tee(sys.stdout, log)), contextlib.redirect_stderr(Tee(sys.stderr, log)):
        try:
            before = snapshot(); check_sources(sealed, before); save("sources-before-queue.json", before)
            spec = importlib.util.spec_from_file_location("cinder_captured_original_producer_dev", ROOT / "scripts/dev/dev.py")
            dev = importlib.util.module_from_spec(spec); sys.modules[spec.name] = dev
            policy = sys.dont_write_bytecode
            try:
                sys.dont_write_bytecode = True; spec.loader.exec_module(dev)
            finally:
                sys.dont_write_bytecode = policy
            child_env = dict(os.environ)
            child_env["CINDER_CAPTURED_ORIGINAL_OUTPUT"] = str(out)
            child_env["CINDER_CAPTURED_ORIGINAL_SOURCES"] = json.dumps(["res://" + name for name in NAMES])
            context = dev.ProjectContext(root=ROOT, environ=child_env)
            command = [str(dev.resolve_godot(context)), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log"), "--script", "res://" + SCRIPT]
            save("command.json", {"argv": command, "cwd": str(ROOT), "timeout_seconds_after_acquisition": TIMEOUT, "environment_scope": "Only output and exact source-name list added to owned child; inherited environment values are not dumped."})
            queue.update({"queued": True, "queued_at": now(), "lock_path": str(dev.shared_lock_path(ROOT))}); save("queue.json", queue)
            with dev.godot_lock(context.root) as lock_fd:
                queue.update({"acquired": True, "acquired_at": now()}); save("queue.json", queue)
                at_lock = snapshot(); check_sources(sealed, at_lock); save("sources-at-lock.json", at_lock)
                result.update({"engine_started": True, "engine_started_at": now()}); save("result.json", result)
                returned = dev.run_validation(command, context, lock_fd, TIMEOUT, detect_godot_errors=True)
                result.update({"owned_child_terminal": True, "owned_child_terminal_at": now(), "engine_return_code": returned, "return_code_scope": "Canonical dev return. Zero proves owned child wait returned zero; nonzero may be a synthetic timeout/script-error result because this API does not expose a separate child exit status."}); save("result.json", result)
                after = snapshot(); save("sources-after-child.json", after); check_sources(sealed, after)
            queue["lock_context_released_at"] = now(); save("queue.json", queue)
            log.flush()
            if returned != 0:
                raise ValueError("Canonical owned validation returned " + str(returned))
            report_path = out / "native-report.json"
            report = json.loads(report_path.read_text())
            rows = report["rows"]
            assert report["checks"] == len(rows) > 0
            assert [row["check"] for row in rows] == list(range(1, len(rows) + 1))
            assert report["failures"] == sum(not row["ok"] for row in rows) == 0
            assert all(type(row["ok"]) is bool for row in rows)
            assert report["first_failure"] == {} and report["complete"] is True and report["success"] is True
            expected = {"res://" + name: value for name, value in sealed.items()}
            assert report["source_before"] == report["source_after"] == expected
            packets = report["packets"]
            pairs = {(r["profile"], r["stage"]) for r in packets}
            required = {(p, s) for p in ("assisted", "standard") for s in ("recording", "warning")}
            allowed = required | {(p, "gen0") for p in ("assisted", "standard")}
            assert required <= pairs <= allowed and len(packets) == len(pairs)
            assert all(not row["payload_exported"] and row["stage"] == "gen0" for row in report["unsupported"])
            for packet in packets:
                exact_file, store_file = out / packet["exact_file"], out / packet["store_file"]
                assert exact_file.parent == store_file.parent == out
                assert sha(exact_file) == packet["exact_sha256"] and exact_file.stat().st_size == packet["exact_bytes"]
                assert sha(store_file) == packet["store_sha256"] and store_file.stat().st_size == packet["store_bytes"]
                envelope = json.loads(store_file.read_text())
                wire = exact_file.read_text()
                assert envelope["format_version"] == 2 and envelope["payload_json"] == wire and envelope["sha256"] == hashlib.sha256(wire.encode()).hexdigest()
                assert packet["api_revision"] == "act3-crystalman-captured-phase-2" and packet["schema_version"] == 2
                assert packet["phase"] == ("settling" if packet["stage"] == "gen0" else packet["stage"])
            raw = (out / "raw.log").read_text()
            lines = re.findall(r"(?m)^CINDER_CAPTURED_ORIGINAL_REPORT path=(.+) sha256=([0-9a-f]{64})$", raw)
            assert lines == [(str(report_path), sha(report_path))]
            footer = re.findall(r"(?m)^Captured original API2 producer: (\d+) checks/(\d+) failures; complete=(true|false); packets=(\d+)$", raw)
            assert footer == [(str(report["checks"]), "0", "true", str(len(packets)))]
            result.update({"passed": True, "native_report": {"path": str(report_path), "sha256": sha(report_path), "checks": report["checks"], "failures": 0, "complete": True, "packets": packets, "literal_report_footer_and_store_joins": True}})
            code = 0
        except KeyboardInterrupt:
            # Canonical run_validation handles only its owned direct child.
            result.update({"interrupted": True, "error": "Interrupted; dev owns child cleanup."}); code = 130
        except Exception as exc:
            result["error"] = str(exc); print("Original captured producer failed:", exc, flush=True)
        finally:
            result.update({"closed": True, "closed_at": now(), "runner_return_code": code})
            save("result.json", result)
            save("sources-at-runner-close.json", snapshot())
            print("Original captured producer runner CLOSED code=" + str(code), flush=True)
    save("evidence-index.json", {"created_after_raw_log_close": True, "files": {path.name: {"sha256": sha(path), "bytes": path.stat().st_size} for path in sorted(out.iterdir()) if path.is_file()}, "scope": result["scope"]})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
