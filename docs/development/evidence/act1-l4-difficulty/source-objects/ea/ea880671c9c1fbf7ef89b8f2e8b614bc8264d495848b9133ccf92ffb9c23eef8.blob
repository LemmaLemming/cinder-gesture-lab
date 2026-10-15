"""Root-only, fixed-subset court checks through the canonical Godot queue."""
import argparse
import contextlib
import datetime
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import time
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
TEST = "tests/acts/act1/a1_l4_difficulty_arrangement.gd"
REPORT_ENV = "CINDER_COURT_ARRANGEMENT_REPORT"
FILES = {
    "scripts/acts/act1/selenite_court.gd",
    "scripts/acts/act1/selenite_court_layout.gd",
    "scripts/acts/act1/selenite_court_codec.gd",
    "scripts/acts/act1/mushroom_selenite.gd",
    "scripts/acts/act1/selenite_king.gd",
    "scripts/combat/encounter_arrangement.gd",
    "scripts/combat/threat_scheduler.gd",
    "scripts/combat/lane_mechanism.gd",
    "scripts/campaign/shell.gd",
    "scripts/campaign/level.gd",
    "scripts/campaign/registry.gd",
    "scripts/campaign/attempts.gd",
    "scripts/campaign/save_store.gd",
    "scripts/campaign/exact_json.gd",
    "scripts/campaign/snapshot_codec.gd",
    "scripts/player.gd",
    "scripts/game.gd",
    "scripts/ui/campaign_menu.gd",
    "scenes/main.tscn",
    "scenes/acts/act1/a1_l4.tscn",
    "tests/acts/act1/a1_l4_whole_save.gd",
    "tests/acts/act1/fixtures/a1_l4_difficulty_legacy_packets.json",
    "tests/acts/act1/a1_l4_whole_portrait.gd",
    "tests/act1_l4_registration_smoke.gd",
    "data/campaign/registry.json",
    "scripts/dev/dev.py",
    "project.godot",
    str(Path(__file__).resolve().relative_to(ROOT)),
    TEST,
}
UIDS = {p + ".uid" for p in FILES if p.endswith(".gd")}
SCOPE = "Fixed named sources/sidecars only; not a global class/resource/dependency/UID or frozen-bank census. Whole-project import may alter derived metadata outside this subset. No full-route, balance, performance, visual, release or new level acceptance credit."


def stamp():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def observation():
    return {p: sha(ROOT / p) if (ROOT / p).is_file() else None for p in sorted(FILES | UIDS)}


class Tee:
    def __init__(self, file, original):
        self.file, self.original = file, original

    def write(self, value):
        self.file.write(value)
        self.original.write(value)
        return len(value)

    def flush(self):
        self.file.flush()
        self.original.flush()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("phase", choices=["import", "parse", "pure", "standard", "assisted", "challenge", "legacy", "portrait"])
    parser.add_argument("--seal", type=Path, required=True)
    args = parser.parse_args()
    out = HERE / (args.phase + "-" + datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S") + "-" + uuid.uuid4().hex[:8])
    out.mkdir()
    print("Unique court evidence: " + str(out), flush=True)
    result = {"phase": args.phase, "started": stamp(), "scope": SCOPE, "engine_started_via_dev": False, "validation_returned": False, "passed": False}
    code = 2
    started = time.monotonic()
    with (out / "raw.log").open("w") as raw:
        with contextlib.redirect_stdout(Tee(raw, sys.stdout)), contextlib.redirect_stderr(Tee(raw, sys.stderr)):
            try:
                seal_sha = sha(args.seal)
                seal = json.loads(args.seal.read_text())
                assert seal.get("sealed") is True and seal.get("root") == str(ROOT)
                expected = seal["files"]
                assert set(expected) == FILES | UIDS
                missing = {p for p, h in expected.items() if h is None}
                assert not missing or args.phase == "import" and missing == {TEST + ".uid"}
                before = observation()
                save(out / "sources-before-queue.json", before)
                assert before == expected, "Root sealed named inputs drifted"
                save(out / "seal-used.json", seal)
                sys.dont_write_bytecode = True
                spec = importlib.util.spec_from_file_location("cinder_court_dev", ROOT / "scripts/dev/dev.py")
                dev = importlib.util.module_from_spec(spec)
                sys.modules[spec.name] = dev
                spec.loader.exec_module(dev)
                env = dict(os.environ)
                env.pop(REPORT_ENV, None)
                env.pop("CINDER_COURT_PORTRAIT_DIR", None)
                report_path = out / "native-report.json"
                if args.phase not in ["import", "parse"]:
                    env[REPORT_ENV] = str(report_path)
                context = dev.ProjectContext(root=ROOT, environ=env)
                if args.phase == "portrait":
                    env["CINDER_COURT_PORTRAIT_DIR"] = str(out)
                    context = dev.ProjectContext(root=ROOT, environ=env)
                command = [str(dev.resolve_godot(context)), "--path", str(ROOT)]
                if args.phase != "portrait": command += ["--headless"]
                command += ["--log-file", str(out / "engine.log")]
                if args.phase == "import":
                    command += ["--editor", "--import"]
                else:
                    command += ["--script", "res://" + TEST]
                    command += ["--check-only"] if args.phase == "parse" else ["--", "--profile=" + ("challenge" if args.phase == "portrait" else args.phase)]
                save(out / "command.json", {"argv": command, "cwd": str(ROOT), "timeout_after_queue_s": 180, "report_env": {REPORT_ENV: str(report_path)} if REPORT_ENV in env else {}})
                save(out / "queue.json", {"queued": stamp(), "lock": str(dev.shared_lock_path(ROOT)), "acquired": False})
                with dev.godot_lock(ROOT) as lock_fd:
                    save(out / "queue.json", {"acquired": stamp(), "lock": str(dev.shared_lock_path(ROOT))})
                    at_lock = observation()
                    save(out / "sources-at-lock.json", at_lock)
                    assert at_lock == expected and sha(args.seal) == seal_sha, "Queued source/seal drift"
                    save(out / "lifecycle.json", {"state": "RUNNING", "at": stamp(), "ownership": "Canonical dev owns/waits its direct child; never foreign processes/locks"})
                    result["engine_started_via_dev"] = True
                    code = dev.run_validation(command, context, lock_fd, 180, detect_godot_errors=True)
                    result.update({"validation_returned": True, "dev_return_code": code, "owned_direct_child_wait_zero": code == 0})
                    after = observation()
                    save(out / "sources-after-child.json", after)
                    changed = [p for p, h in expected.items() if h is not None and after[p] != h]
                    added = [p for p, h in expected.items() if h is None and after[p] is not None]
                    result["named_source_delta"] = {"changed": changed, "added": added}
                    assert not changed and (args.phase == "import" and added == sorted(missing) or not added and not missing)
                    if code == 0 and args.phase not in ["import", "parse"]:
                        report = json.loads(report_path.read_text())
                        assert report["checks"] == len(report["rows"])
                        assert report["failures"] == sum(x["ok"] is False for x in report["rows"])
                        assert report["complete"] is True and report["success"] is True and report["failures"] == 0 and report["first_failure"] == {}
                        assert report["source_before"] == report["source_after"]
                        for uri, h in report["source_before"].items():
                            assert expected[uri.removeprefix("res://")] == h
                        raw.flush()
                        assert "CINDER_COURT_ARRANGEMENT_REPORT path=" + str(report_path) + " sha256=" + sha(report_path) in (out / "raw.log").read_text()
                        expected_profile = "challenge" if args.phase == "portrait" else args.phase
                        assert f"Court arrangement: {report['checks']} checks/0 failures; complete=true; profile={expected_profile}" in (out / "raw.log").read_text()
                        result["native"] = {"checks": report["checks"], "failures": 0, "report_sha256": sha(report_path), "rows_report_source_footer_join": True}
                    result["passed"] = code == 0
            except Exception as exc:
                print(type(exc).__name__ + ": " + str(exc))
                result["exception"] = type(exc).__name__ + ": " + str(exc)
                code = code if code else 2
            finally:
                result.update({"closed": True, "closed_at": stamp(), "runner_return_code": code, "wall_s_including_queue": time.monotonic() - started})
                save(out / "result.json", result)
                save(out / "lifecycle.json", {"state": "CLOSED", "engine_started_via_dev": result["engine_started_via_dev"], "validation_returned": result["validation_returned"], "code": code, "provenance": "Zero proves canonical child wait0; nonzero may be dev synthetic error/timeout. No child started only when engine_started_via_dev is false."})
    entries = {p.name: {"sha256": sha(p), "bytes": p.stat().st_size} for p in sorted(out.iterdir()) if p.is_file()}
    save(out / "index.json", {"created_after_closed": True, "files": entries, "scope": SCOPE})
    print("Court phase CLOSED code=" + str(code), flush=True)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
