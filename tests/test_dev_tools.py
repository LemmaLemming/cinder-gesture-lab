"""Project-wrapper checks using disposable Git repositories and a fake engine.

No real Godot process, canonical ability ledger or project import cache is used.
Run: python3 -m unittest discover -s tests -p 'test_dev_tools.py' -v
"""

from __future__ import annotations

import importlib.util
import contextlib
import io
import json
import os
from pathlib import Path
import shlex
import signal
import shutil
import subprocess
import sys
import tempfile
import time
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]
SOURCE = REPOSITORY / "scripts/dev/dev.py"
SPEC = importlib.util.spec_from_file_location("cinder_dev_tools", SOURCE)
dev = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(dev)


class DevToolsTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cinder-dev-tests-")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name).resolve()
        self.root = self.directory / "integration"
        self.root.mkdir()
        (self.root / "project.godot").write_text(
            '[application]\nconfig/features=PackedStringArray("4.7", "GL Compatibility")\n',
            encoding="utf-8",
        )
        cli = self.root / "scripts/dev/dev.py"
        cli.parent.mkdir(parents=True)
        shutil.copy2(SOURCE, cli)
        shutil.copy2(REPOSITORY / "scripts/dev/godot-vscode", cli.parent / "godot-vscode")
        (self.root / "tests").mkdir()
        for name, relative in dev.SUITES.items():
            if name != "level_contract":
                (self.root / relative).touch()
        ability = self.root / "scripts/design/ability_usage.py"
        ability.parent.mkdir()
        ability.write_text(
            'import json, sys\nprint(json.dumps({"script": __file__, "arguments": sys.argv[1:]}))\n',
            encoding="utf-8",
        )
        self.environment = dict(os.environ)
        for name in ("CINDER_GODOT", "CINDER_CANONICAL_ROOT"):
            self.environment.pop(name, None)
        self.environment["PYTHONDONTWRITEBYTECODE"] = "1"
        self.log = self.directory / "engine-events.jsonl"
        self.fake = self.make_fake_engine()
        self.environment["CINDER_GODOT"] = str(self.fake)
        self.environment["CINDER_FAKE_LOG"] = str(self.log)

    def make_fake_engine(self):
        script = self.directory / "fake_engine.py"
        script.write_text(
            '''import json, os, sys, time
from pathlib import Path
if "--version" in sys.argv:
    print("4.7.2.stable.official.fake")
    raise SystemExit(0)
if "--help" in sys.argv:
    print("fake engine help")
    raise SystemExit(0)
def event(kind):
    with open(os.environ["CINDER_FAKE_LOG"], "a", encoding="utf-8") as output:
        output.write(json.dumps({"kind": kind, "pid": os.getpid(), "args": sys.argv[1:]}) + "\\n")
event("start")
message = os.environ.get("CINDER_FAKE_OUTPUT")
if message:
    print(message, file=sys.stderr, flush=True)
gate = os.environ.get("CINDER_FAKE_GATE")
deadline = time.monotonic() + 15
while gate and not Path(gate).exists() and time.monotonic() < deadline:
    time.sleep(0.01)
time.sleep(float(os.environ.get("CINDER_FAKE_DELAY", "0")))
event("end")
failure = os.environ.get("CINDER_FAKE_FAIL_MATCH")
raise SystemExit(17 if failure and any(failure in arg for arg in sys.argv[1:]) else 0)
''', encoding="utf-8",
        )
        executable = self.directory / "fake-godot"
        executable.write_text(
            "#!/bin/sh\nexec " + shlex.quote(sys.executable) + " " + shlex.quote(str(script)) + ' "$@"\n',
            encoding="utf-8",
        )
        executable.chmod(0o755)
        return executable

    def configure(self, root=None, **values):
        root = self.root if root is None else root
        directory = root / ".cinder"
        directory.mkdir(exist_ok=True)
        (directory / "local.json").write_text(json.dumps(values), encoding="utf-8")

    def context(self, root=None, environment=None):
        return dev.ProjectContext(root or self.root, self.environment if environment is None else environment)

    def initialize_git(self):
        self.git(self.root, "init", "-q")
        self.git(self.root, "add", ".")
        self.git(
            self.root, "-c", "user.name=Cinder Test", "-c", "user.email=cinder-test@example.invalid",
            "commit", "-qm", "Disposable tooling fixture",
        )

    def git(self, root, *arguments):
        result = subprocess.run(
            ["git", "-C", str(root), *arguments], capture_output=True,
            text=True, timeout=15, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def worktree(self, name):
        root = self.directory / name
        self.git(self.root, "worktree", "add", "-qb", name, str(root))
        return root

    def command(self, root, *arguments):
        return [sys.executable, str(root / "scripts/dev/dev.py"), *arguments]

    def invoke(self, *arguments, root=None, environment=None):
        root = root or self.root
        return subprocess.run(
            self.command(root, *arguments), cwd=root,
            env=self.environment if environment is None else environment,
            capture_output=True, text=True, timeout=15, check=False,
        )

    def events(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()]

    def wait_for_events(self, count, timeout=5):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if len(self.events()) >= count:
                return self.events()
            time.sleep(0.01)
        self.fail(f"Timed out waiting for {count} fake-engine events: {self.events()}")

    def test_engine_resolution_respects_explicit_override_and_local_config(self):
        configured = self.directory / "configured-godot"
        shutil.copy2(self.fake, configured)
        self.configure(godot=str(configured))
        self.assertEqual(dev.resolve_godot(self.context()), self.fake)
        environment = dict(self.environment)
        environment.pop("CINDER_GODOT")
        self.assertEqual(dev.resolve_godot(self.context(environment=environment)), configured)
        environment["CINDER_GODOT"] = str(self.directory / "missing")
        with self.assertRaisesRegex(dev.DevError, "executable"):
            dev.resolve_godot(self.context(environment=environment))

    def test_engine_resolution_uses_checkout_then_canonical_tools_then_path(self):
        canonical = self.directory / "canonical"
        canonical.mkdir()
        (canonical / "project.godot").touch()
        canonical_engine = canonical / dev.GODOT_APP
        canonical_engine.parent.mkdir(parents=True)
        shutil.copy2(self.fake, canonical_engine)
        environment = dict(self.environment)
        environment.pop("CINDER_GODOT")
        environment["CINDER_CANONICAL_ROOT"] = str(canonical)
        environment["PATH"] = str(self.directory)
        self.assertEqual(dev.resolve_godot(self.context(environment=environment)), canonical_engine)
        own_engine = self.root / dev.GODOT_APP
        own_engine.parent.mkdir(parents=True)
        shutil.copy2(self.fake, own_engine)
        self.assertEqual(dev.resolve_godot(self.context(environment=environment)), own_engine)
        own_engine.unlink()
        canonical_engine.unlink()
        path_engine = self.directory / "godot"
        shutil.copy2(self.fake, path_engine)
        self.assertEqual(dev.resolve_godot(self.context(environment=environment)), path_engine)

    def test_configuration_requires_stable_slot_and_absolute_canonical_root(self):
        self.configure(slot="act4")
        with self.assertRaisesRegex(dev.DevError, "slot"):
            self.context()
        self.configure(canonical_root="..")
        with self.assertRaisesRegex(dev.DevError, "absolute"):
            self.context()
        self.configure(canonical_root=str(self.root), slot="act1")
        environment = dict(self.environment, CINDER_CANONICAL_ROOT=str(self.directory / "missing"))
        with self.assertRaisesRegex(dev.DevError, "Canonical root"):
            self.context(environment=environment)

    def prepare_setup_fixture(self):
        shutil.copy2(REPOSITORY / "scripts/dev/setup_vscode.py", self.root / "scripts/dev/setup_vscode.py")
        ledger = self.root / "data/design/ability_usage.json"
        ledger.parent.mkdir(parents=True)
        ledger.write_text("{}\n", encoding="utf-8")
        shutil.copy2(self.root / "scripts/design/ability_usage.py", self.root / "scripts/design/equipment_grid.py")
        code = self.directory / "fake-vscode-cli"
        code.touch()
        return code

    def invoke_setup(self, root, canonical, code):
        # Patch only the macOS application-presence check in this disposable
        # process, so the canonical-root regression is portable without VSCode.
        driver = (
            "import sys; from pathlib import Path; "
            "sys.path.insert(0, sys.argv[1]); import setup_vscode; "
            "setup_vscode.CODE = Path(sys.argv[2]); sys.argv = sys.argv[3:]; "
            "raise SystemExit(setup_vscode.main())"
        )
        return subprocess.run(
            [sys.executable, "-c", driver, str(root / "scripts/dev"), str(code), "setup_vscode.py",
             "--slot", "act1", "--canonical-root", str(canonical), "--godot", str(self.fake)],
            cwd=root, env=self.environment, capture_output=True, text=True,
            timeout=15, check=False,
        )

    def test_setup_rejects_private_or_unrelated_canonical_root_before_overwriting_settings(self):
        code = self.prepare_setup_fixture()
        self.initialize_git()
        worktree = self.worktree("act1")
        self.configure(worktree, canonical_root=str(self.root), godot=str(self.fake), slot="act1")
        workspace = worktree / ".cinder/cinder.code-workspace"
        workspace.write_text('{"existing": "workspace"}\n', encoding="utf-8")
        local = worktree / ".cinder/local.json"
        originals = (local.read_bytes(), workspace.read_bytes())
        unrelated = self.directory / "unrelated"
        shutil.copytree(self.root, unrelated, ignore=shutil.ignore_patterns(".git", ".cinder"))
        self.git(unrelated, "init", "-q")
        for canonical, message in ((worktree, "primary checkout"), (unrelated, "shared Git repository")):
            with self.subTest(canonical=canonical):
                result = self.invoke_setup(worktree, canonical, code)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn(message, result.stderr)
                self.assertEqual((local.read_bytes(), workspace.read_bytes()), originals)
        result = self.invoke_setup(worktree, self.root, code)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(local.read_text(encoding="utf-8")), {
            "canonical_root": str(self.root), "godot": str(self.fake), "slot": "act1",
        })
        generated = json.loads(workspace.read_text(encoding="utf-8"))
        self.assertEqual(generated["settings"]["godotTools.lsp.serverPort"], 6015)
        self.assertEqual(generated["settings"]["godotTools.editorPath.godot4"], str(worktree / "scripts/dev/godot-vscode"))

    def test_setup_requires_both_canonical_design_tools_without_changing_existing_settings(self):
        code = self.prepare_setup_fixture()
        self.initialize_git()
        worktree = self.worktree("act1")
        self.configure(worktree, canonical_root=str(self.root), godot=str(self.fake), slot="act1")
        workspace = worktree / ".cinder/cinder.code-workspace"
        workspace.write_text("{}\n", encoding="utf-8")
        local = worktree / ".cinder/local.json"
        originals = (local.read_bytes(), workspace.read_bytes())
        (self.root / "scripts/design/equipment_grid.py").unlink()
        result = self.invoke_setup(worktree, self.root, code)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("equipment_grid.py", result.stderr)
        self.assertEqual((local.read_bytes(), workspace.read_bytes()), originals)

    def test_ability_proxy_uses_primary_checkout_and_rejects_private_fallbacks(self):
        self.initialize_git()
        worktree = self.worktree("act1")
        with self.assertRaisesRegex(dev.DevError, "explicit"):
            dev.ability_command(self.context(root=worktree), ["status"])
        self.configure(worktree, canonical_root=str(self.root), slot="act1")
        command = dev.ability_command(self.context(root=worktree), ["available", "--level", "A1-L1"])
        self.assertEqual(command[1], str(self.root / "scripts/design/ability_usage.py"))
        self.assertEqual(command[2:4], ["--root", str(self.root)])
        result = self.invoke("ability", "status", root=worktree)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["arguments"], ["--root", str(self.root), "status"])
        self.configure(worktree, canonical_root=str(worktree), slot="act1")
        with self.assertRaisesRegex(dev.DevError, "primary checkout"):
            dev.ability_command(self.context(root=worktree), ["status"])

    def test_ability_proxy_rejects_other_repository_and_root_ledger_overrides(self):
        self.initialize_git()
        other = self.directory / "other"
        shutil.copytree(self.root, other, ignore=shutil.ignore_patterns(".git"))
        self.git(other, "init", "-q")
        self.configure(canonical_root=str(other))
        with self.assertRaisesRegex(dev.DevError, "shared Git repository"):
            dev.ability_command(self.context(), ["reserve"])
        self.configure(canonical_root=str(self.root))
        for arguments in (
            ["--root", str(other), "status"], ["status", "--ledger=/tmp/private.json"],
            ["status", "--ledger", "/tmp/private.json"], ["unknown-command"],
        ):
            with self.subTest(arguments=arguments), self.assertRaises(dev.DevError):
                dev.ability_command(self.context(), arguments)

    def test_standalone_ability_root_defaults_to_own_checkout(self):
        command = dev.ability_command(self.context(), ["status"])
        self.assertEqual(command[2:4], ["--root", str(self.root)])
        self.configure(slot="act2")
        with self.assertRaisesRegex(dev.DevError, "private ledger"):
            dev.ability_command(self.context(), ["status"])

    def test_equipment_proxy_targets_canonical_grid_and_rejects_private_roots(self):
        grid = self.root / "scripts/design/equipment_grid.py"
        shutil.copy2(self.root / "scripts/design/ability_usage.py", grid)
        self.initialize_git()
        worktree = self.worktree("act2")
        with self.assertRaisesRegex(dev.DevError, "explicit"):
            dev.equipment_command(self.context(root=worktree), ["status"])
        self.configure(worktree, canonical_root=str(self.root), slot="act2")
        result = self.invoke("equipment", "status", "--markdown", root=worktree)
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["script"], str(grid))
        self.assertEqual(payload["arguments"], ["--root", str(self.root), "status", "--markdown"])
        with self.assertRaisesRegex(dev.DevError, "overrides"):
            dev.equipment_command(self.context(root=worktree), ["check", "--root", str(worktree)])
        with self.assertRaisesRegex(dev.DevError, "Unknown equipment"):
            dev.equipment_command(self.context(root=worktree), ["init"])

    def test_check_imports_then_all_present_suites_and_stops_on_failure(self):
        (self.root / dev.SUITES["level_contract"]).touch()
        result = self.invoke("check")
        self.assertEqual(result.returncode, 0, result.stderr)
        starts = [event["args"] for event in self.events() if event["kind"] == "start"]
        self.assertEqual(len(starts), 6)
        self.assertEqual(starts[0][-2:], ["--headless", "--import"])
        self.assertEqual([arguments[-1] for arguments in starts[1:]], ["res://" + relative for relative in dev.SUITES.values()])
        self.log.unlink()
        environment = dict(self.environment, CINDER_FAKE_FAIL_MATCH="equipment_smoke.gd")
        result = self.invoke("check", environment=environment)
        self.assertEqual(result.returncode, 17, result.stderr)
        starts = [event for event in self.events() if event["kind"] == "start"]
        self.assertEqual(len(starts), 3)
        self.assertTrue(starts[-1]["args"][-1].endswith("equipment_smoke.gd"))

    def test_run_passes_level_to_shared_entry_and_rejects_escape(self):
        level = self.root / "scenes/levels/act1/first.tscn"
        level.parent.mkdir(parents=True)
        level.touch()
        result = self.invoke("run", "--level-scene", "scenes/levels/act1/first.tscn")
        self.assertEqual(result.returncode, 0, result.stderr)
        arguments = self.events()[0]["args"]
        self.assertEqual(arguments[-2:], ["--", "--level-scene=res://scenes/levels/act1/first.tscn"])
        outside = self.directory / "outside.tscn"
        outside.touch()
        with self.assertRaisesRegex(dev.DevError, "inside"):
            dev.scene_uri(self.context(), str(outside))

    def test_editor_and_engine_wrapper_use_slot_ports_and_preserve_explicit_ports(self):
        self.configure(slot="act3")
        result = self.invoke("editor")
        self.assertEqual(result.returncode, 0, result.stderr)
        arguments = self.events()[0]["args"]
        self.assertIn("6035", arguments)
        self.assertIn("6036", arguments)
        self.assertIn("tcp://127.0.0.1:6037", arguments)
        self.log.unlink()
        result = subprocess.run(
            [sys.executable, str(self.root / "scripts/dev/godot-vscode"), "--editor", "--path", str(self.root), "--lsp-port", "7777"],
            cwd=self.root, env=self.environment, capture_output=True, text=True, timeout=15, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        arguments = self.events()[0]["args"]
        self.assertEqual(arguments.count("--lsp-port"), 1)
        self.assertIn("7777", arguments)
        self.assertNotIn("6035", arguments)

    def test_raw_version_query_does_not_create_a_heavy_session_lock(self):
        result = self.invoke("engine", "--version")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("4.7.2", result.stdout)
        self.assertFalse(dev.shared_lock_path(self.root).exists())
        self.assertEqual(self.events(), [])

    def test_doctor_reports_readiness_without_consulting_grid_or_dumping_environment(self):
        grid = self.root / "scripts/design/equipment_grid.py"
        grid.write_text('raise RuntimeError("doctor must not run the equipment grid")\n', encoding="utf-8")
        environment = dict(self.environment, CINDER_TEST_SECRET="must-not-appear-in-doctor-output")
        result = self.invoke("doctor", environment=environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Baseline readiness: unverified", result.stdout)
        self.assertIn("dev.py equipment status", result.stdout)
        self.assertNotIn("must-not-appear-in-doctor-output", result.stdout + result.stderr)
        self.assertEqual(self.events(), [])

    def test_zero_exit_script_error_aborts_check_before_smoke_suites(self):
        environment = dict(self.environment, CINDER_FAKE_OUTPUT="SCRIPT ERROR: Parse Error: broken.gd")
        result = self.invoke("check", environment=environment)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("script or project-resource error", result.stderr)
        self.assertEqual(len([event for event in self.events() if event["kind"] == "start"]), 1)

    def test_validation_ignores_certificate_permission_noise(self):
        environment = dict(self.environment, CINDER_FAKE_OUTPUT="ERROR: Could not get macOS CA certificates: permission denied")
        result = self.invoke("import", environment=environment)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("CA certificates", result.stdout)
        self.assertFalse(dev.SCRIPT_FAILURE.search("ERROR: Could not get macOS CA certificates: permission denied"))
        self.assertTrue(dev.SCRIPT_FAILURE.search('ERROR: Failed to load script "res://bad.gd" with error "Parse error".'))
        self.assertTrue(dev.SCRIPT_FAILURE.search('ERROR: Failed loading resource: res://bad.tscn.'))

    def test_bounded_validation_stops_only_its_child_and_releases_shared_lock(self):
        gate = self.directory / "validation-never-released"
        environment = dict(self.environment, CINDER_FAKE_GATE=str(gate))
        context = self.context(environment=environment)
        output, errors = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            with dev.godot_lock(self.root) as lock_fd:
                code = dev.run_validation([str(self.fake), "--headless", "--import"], context, lock_fd, 0.2)
        self.assertEqual(code, 124)
        self.assertIn("timed out", errors.getvalue())
        result = self.invoke("run")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        # On a loaded machine the timeout may stop Python before its first log.
        # Either way, the next session must acquire the lock and finish normally.
        kinds = [event["kind"] for event in self.events()]
        self.assertEqual(kinds[-2:], ["start", "end"])
        self.assertEqual(kinds.count("end"), 1)

    def test_linked_worktrees_serialize_fake_engine_processes(self):
        self.initialize_git()
        act1, act2 = self.worktree("act1"), self.worktree("act2")
        self.assertEqual(dev.shared_lock_path(act1), dev.shared_lock_path(act2))
        self.assertEqual(dev.shared_lock_path(act1), self.root / ".cinder/locks/godot.lock")
        self.assertFalse((self.root / ".git/cinder-dev").exists())
        environment = dict(self.environment, CINDER_FAKE_DELAY="0.2")
        processes = [subprocess.Popen(
            self.command(root, "run"), cwd=root, env=environment,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        ) for root in (act1, act2)]
        try:
            for process in processes:
                stdout, stderr = process.communicate(timeout=10)
                self.assertEqual(process.returncode, 0, stdout + stderr)
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.communicate(timeout=5)
        events = self.events()
        self.assertEqual([event["kind"] for event in events], ["start", "end", "start", "end"])
        self.assertNotEqual(events[0]["pid"], events[2]["pid"])

    def test_child_retains_lock_when_its_wrapper_is_killed(self):
        self.assert_child_retains_lock(signal.SIGKILL)

    def test_interrupting_wrapper_does_not_kill_child_or_release_its_lock(self):
        self.assert_child_retains_lock(signal.SIGINT)

    def assert_child_retains_lock(self, wrapper_signal):
        self.initialize_git()
        act1, act2 = self.worktree("act1"), self.worktree("act2")
        gate = self.directory / "release-fake-child"
        environment = dict(self.environment, CINDER_FAKE_GATE=str(gate))
        first = subprocess.Popen(
            self.command(act1, "run"), cwd=act1, env=environment,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        second = None
        try:
            self.wait_for_events(1)
            first.send_signal(wrapper_signal)  # Only the disposable Python wrapper, never real Godot.
            first.wait(timeout=5)
            second = subprocess.Popen(
                self.command(act2, "run"), cwd=act2, env=environment,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            )
            time.sleep(0.2)
            self.assertEqual(len(self.events()), 1, "Second engine overlapped the inherited lock.")
            self.assertIsNone(second.poll())
            gate.touch()
            stdout, stderr = second.communicate(timeout=10)
            self.assertEqual(second.returncode, 0, stdout + stderr)
            self.wait_for_events(4)
            self.assertEqual([event["kind"] for event in self.events()], ["start", "end", "start", "end"])
        finally:
            gate.touch()
            if first.poll() is None:
                first.kill()
                first.wait(timeout=5)
            if second is not None and second.poll() is None:
                second.kill()
                second.communicate(timeout=5)


if __name__ == "__main__":
    unittest.main()
