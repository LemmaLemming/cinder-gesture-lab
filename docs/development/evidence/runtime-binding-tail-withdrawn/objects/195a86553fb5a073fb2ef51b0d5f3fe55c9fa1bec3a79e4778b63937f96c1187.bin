"""Host-only mocked checks. Never imports dev, launches Godot or edits live paths."""
from pathlib import Path
import contextlib
import hashlib
import importlib.util
import io
import json
import os
import tempfile
import types
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
module_spec = importlib.util.spec_from_file_location("binding_tail_host_under_test", HERE / "run.py")
host = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(host)


class HostChecks(unittest.TestCase):
    def packet(self, variant="original", failed=False):
        row = {"check": 1, "ok": not failed, "label": "MOCKED HOST PROTOCOL ONLY", "note": {}}
        return {"kind": "authored-binding-tail-differential-1", "variant": variant,
                "source_sha256": "a" * 64, "checks": 1, "failures": int(failed),
                "first_failure": row if failed else {}, "complete": not failed,
                "success": not failed, "rows": [row], "observations": [{"label": "mock", "value": 1}],
                "initial_wire_exact": "opaque-mocked-wire"}

    def fake_phase(self, root, behavior):
        class FakeDev:
            def ProjectContext(self, root, environ):
                return types.SimpleNamespace(root=root, canonical_root=root, environ=environ)
            def run_validation(self, command, context, lock_fd, timeout, detect_godot_errors):
                if behavior == "interrupt":
                    raise KeyboardInterrupt()
                if behavior == "missing":
                    return 1
                packet = HostChecks().packet(failed=behavior == "failed")
                native = Path(context.environ["CINDER_BINDING_TAIL_REPORT"])
                native.write_text(json.dumps(packet))
                print("CINDER_BINDING_TAIL_REPORT=" + str(native) + " sha256=" + hashlib.sha256(native.read_bytes()).hexdigest())
                print("BINDING TAIL DIFFERENTIAL: 1 checks, %d failures; complete=%s" % (packet["failures"], str(packet["complete"]).lower()))
                if behavior == "CA":
                    print('ERROR: Condition "ret != noErr" is true. Returning: ""')
                return 2 if behavior == "failed" else 0
        fake_spec = {"engine_expected": {"sha256": "engine"}, "selected_fixture": "private-mocked-leaf.gd",
                     "timeout_after_lock_seconds": 180, "subject_variants": {"original": {"sha256": "a" * 64}}}
        with patch.object(host, "snapshot", return_value={}), patch.object(host, "engine_record", return_value={"sha256": "engine"}), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return host.execute_phase(FakeDev(), fake_spec, root, "original", types.SimpleNamespace(environ={}), Path("fake-not-executed"), -1)

    def test_complete_mocked_phase_closes_and_indexes(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            result, _ = self.fake_phase(Path(name), "normal")
            self.assertTrue(result["closed"] and result["passed"] and result["native_functional_pass"])
            self.assertTrue((Path(name) / "original/evidence-index.json").is_file())
            self.assertIsNone(result["independent_os_child_return_code"])

    def test_CA_is_nonclean_but_functional_fact_retained(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            result, _ = self.fake_phase(Path(name), "CA")
            self.assertTrue(result["native_functional_pass"])
            self.assertFalse(result["passed"])
            self.assertEqual(result["runner_return_code"], 2)
            self.assertEqual(len(result["raw_diagnostic_lines"]), 1)

    def test_missing_report_is_not_manufactured(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            result, packet = self.fake_phase(Path(name), "missing")
            self.assertFalse(result["passed"] or result["native_functional_pass"])
            self.assertIsNone(packet)
            self.assertFalse((Path(name) / "original/native-report.json").exists())

    def test_failed_report_retains_actual_failure(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            result, packet = self.fake_phase(Path(name), "failed")
            self.assertFalse(result["native_functional_pass"])
            self.assertEqual(packet["failures"], 1)
            self.assertTrue((Path(name) / "original/native-report-retention.json").is_file())

    def test_cooperative_interruption_closes_indexes_then_propagates(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            with self.assertRaises(KeyboardInterrupt):
                self.fake_phase(Path(name), "interrupt")
            result = host.read(Path(name) / "original/result.json")
            self.assertTrue(result["closed"])
            self.assertEqual(result["runner_return_code"], 130)
            self.assertTrue((Path(name) / "original/evidence-index.json").is_file())

    def test_semantic_projection_preserves_types_and_order(self):
        left, right = self.packet(), self.packet("candidate")
        self.assertEqual(host.semantic_projection(left), host.semantic_projection(right))
        right["observations"][0]["value"] = 1.0
        self.assertNotEqual(host.semantic_projection(left), host.semantic_projection(right))
        right["observations"][0]["value"] = True
        self.assertNotEqual(host.semantic_projection(left), host.semantic_projection(right))

    def test_atomic_subject_copy_restores_bytes_and_mode_in_private_temp(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            target = Path(name) / "PRIVATE_MOCK_SUBJECT.gd"
            target.write_bytes(b"mock original\n")
            os.chmod(target, 0o644)
            before, original = host.file_record(target)
            host.replace_subject(target, b"mock candidate\n", "0644")
            try:
                self.assertEqual(target.read_bytes(), b"mock candidate\n")
                raise RuntimeError("mocked child failure")
            except RuntimeError:
                pass
            finally:
                host.replace_subject(target, original, before["mode"])
            self.assertEqual(host.file_record(target)[0], before)


if __name__ == "__main__":
    stream = io.StringIO()
    result = unittest.TextTestRunner(stream=stream, verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(HostChecks))
    payload = {"kind": "HOST_ONLY_MOCKED_TESTS_NOT_NATIVE", "tests": result.testsRun,
               "failures": len(result.failures), "errors": len(result.errors), "success": result.wasSuccessful(),
               "engine_executed": False, "canonical_dev_imported": False, "live_subject_mutated": False,
               "native_or_performance_credit": False, "output": stream.getvalue()}
    (HERE / "HOST_TESTS.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({key: value for key, value in payload.items() if key != "output"}))
    raise SystemExit(0 if result.wasSuccessful() else 1)
