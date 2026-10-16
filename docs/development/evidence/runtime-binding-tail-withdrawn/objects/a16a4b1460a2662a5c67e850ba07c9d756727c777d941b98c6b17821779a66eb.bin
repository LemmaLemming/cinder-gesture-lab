"""Host-only parser/mocked-child checks. Never launches engine or imports dev."""
from pathlib import Path
import contextlib
import copy
import importlib.util
import io
import json
import os
import tempfile
import types
import unittest
from unittest.mock import patch
import cost_metrics

HERE = Path(__file__).resolve().parent
selected = importlib.util.spec_from_file_location("binding_tail_cost_host_test", HERE / "run.py")
host = importlib.util.module_from_spec(selected)
selected.loader.exec_module(host)
HISTORICAL_RAW = (HERE / "host-tests-original113.log.txt").read_text()


class HostChecks(unittest.TestCase):
    def profile(self):
        return cost_metrics.validate_profile(HISTORICAL_RAW, cost_metrics.extract_profile(HISTORICAL_RAW))[0]

    def test_historical_parser_only_not_new_native(self):
        _, joined = cost_metrics.validate_profile(HISTORICAL_RAW, cost_metrics.extract_profile(HISTORICAL_RAW))
        self.assertEqual((joined["checks"], joined["automatic"]["count"], joined["manual"]["count"]), (113, 72, 1))
        self.assertEqual([joined["probes"][api]["count"] for api in cost_metrics.PROBES], [3] * 5)
        self.assertFalse(joined["native_structured_row_array"])

    def test_incoherent_advance_timing_refuses(self):
        packet = self.profile()
        packet["advance_samples"][0]["inclusive_us"] += 1
        with self.assertRaises(ValueError):
            cost_metrics.validate_profile(HISTORICAL_RAW, json.dumps(packet))

    def test_probe_clock_change_refuses(self):
        packet = self.profile()
        packet["separate_fixed_clock_guard_probes"][0]["clock_after_s"] += 1.0
        with self.assertRaises(ValueError):
            cost_metrics.validate_profile(HISTORICAL_RAW, json.dumps(packet))

    def test_semantics_exclude_costs_but_retain_native_receipts(self):
        packet = self.profile()
        changed = copy.deepcopy(packet)
        changed["advance_samples"][0]["inclusive_us"] += 1
        changed["wall_elapsed_us"] += 100
        self.assertEqual(cost_metrics.semantic_projection(packet), cost_metrics.semantic_projection(changed))
        changed["advance_samples"][0]["automatic_native_tick"] = 1
        self.assertNotEqual(cost_metrics.semantic_projection(packet), cost_metrics.semantic_projection(changed))

    def test_metric_units_and_zero_delta(self):
        packet = self.profile()
        compared = cost_metrics.comparison(packet, copy.deepcopy(packet))
        metric = compared["automatic_advance"]["metrics"]["inclusive_total_us"]
        self.assertEqual(metric["original_ms"], metric["original_us"] / 1000)
        self.assertEqual(metric["candidate_minus_original_ms"], 0)
        self.assertFalse(compared["steady_fps_or_cpu_claim"])

    def fake_phase(self, root, behavior):
        class FakeChild:
            pid = 999999  # MOCK ONLY: no process exists or is signaled.
            def __init__(self):
                self.code = None
            def poll(self):
                return self.code
            def wait(self, timeout=5):
                return self.code
        class FakeDev:
            def __init__(self):
                self.subprocess = types.SimpleNamespace(Popen=lambda *args, **kwargs: FakeChild())
            def ProjectContext(self, root, environ):
                return types.SimpleNamespace(root=root, canonical_root=root, environ=environ)
            def stop_validation(self, child):
                child.code = -15
            def run_validation(self, command, context, lock_fd, timeout, detect_godot_errors):
                child = self.subprocess.Popen(command, cwd=host.ROOT, env=context.environ, pass_fds=(lock_fd,))
                if behavior == "interrupt":
                    raise KeyboardInterrupt()
                if behavior != "missing":
                    print(HISTORICAL_RAW, end="")  # All original CA diagnostics retained.
                child.code = -15 if behavior == "timeout" else (1 if behavior == "missing" else 0)
                return 124 if behavior == "timeout" else (1 if behavior == "missing" else 0)
        spec = {"engine_expected": {"sha256": "engine"}, "selected_fixture": "mock-not-executed.gd",
                "timeout_after_lock_seconds": 180, "subject_variants": {"original": {"sha256": "a" * 64}}}
        with patch.object(host, "snapshot", return_value={}), patch.object(host, "engine_record", return_value={"sha256": "engine"}), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return host.execute_phase(FakeDev(), spec, root, "original", types.SimpleNamespace(environ={}), Path("fake-not-executed"), -1)

    def test_mocked_CA_remains_host2_and_Popen0(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            result, _ = self.fake_phase(Path(name), "CA")
            self.assertTrue(result["closed"] and result["native_functional_pass"])
            self.assertFalse(result["passed"])
            self.assertEqual(result["runner_return_code"], 2)
            self.assertEqual(result["canonical_validation_return_code"], 0)
            self.assertEqual(result["owned_popen_children"][0]["popen_return_code"], 0)
            self.assertTrue(result["raw_diagnostic_lines"])

    def test_mocked_API124_is_distinct_from_Popen_minus15(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            result, _ = self.fake_phase(Path(name), "timeout")
            self.assertFalse(result["native_functional_pass"])
            self.assertEqual(result["canonical_validation_return_code"], 124)
            self.assertEqual(result["owned_popen_children"][0]["popen_return_code"], -15)

    def test_missing_profile_is_not_reconstructed(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            result, packet = self.fake_phase(Path(name), "missing")
            self.assertFalse(result["native_functional_pass"])
            self.assertIsNone(packet)
            self.assertFalse((Path(name) / "original/native-profile.json").exists())

    def test_interruption_closes_owned_fake_then_indexes(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            with self.assertRaises(KeyboardInterrupt):
                self.fake_phase(Path(name), "interrupt")
            result = host.read(Path(name) / "original/result.json")
            self.assertEqual(result["runner_return_code"], 130)
            self.assertTrue(result["owned_popen_children"][0]["closed"])
            self.assertTrue((Path(name) / "original/evidence-index.json").is_file())

    def test_private_atomic_copy_and_finally_restore(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            subject = Path(name) / "MOCK_ONLY.gd"
            subject.write_bytes(b"mock original\n")
            os.chmod(subject, 0o644)
            before, original = host.file_record(subject)
            try:
                host.replace_subject(subject, b"mock candidate\n", "0644", before)
            finally:
                host.replace_subject(subject, original, before["mode"], host.file_record(subject)[0])
            self.assertEqual(host.file_record(subject)[0], before)

    def test_immediate_preswap_guard_preserves_foreign_bytes_mode_and_type(self):
        # Each mutation occurs only when final file_record runs after the private
        # replacement is fully prepared, immediately before canonical replace.
        for mutation in ["bytes", "mode", "symlink", "directory"]:
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory(dir=HERE) as name:
                folder = Path(name)
                subject = folder / "MOCK_ONLY.gd"
                subject.write_bytes(b"mock original\n")
                os.chmod(subject, 0o644)
                expected = host.file_record(subject)[0]
                target = folder / "FOREIGN_TARGET"
                target.write_bytes(b"foreign target, never follow\n")
                actual_record = host.file_record
                changed = False
                def final_observation(path):
                    nonlocal changed
                    if path == subject and not changed:
                        self.assertTrue(list(folder.glob("MOCK_ONLY.gd.binding-tail-owned-*.tmp")))
                        changed = True
                        if mutation == "bytes":
                            subject.write_bytes(b"manual foreign edit\n")
                        elif mutation == "mode":
                            os.chmod(subject, 0o600)
                        elif mutation == "symlink":
                            subject.unlink()
                            subject.symlink_to(target.name)
                        else:
                            subject.unlink()
                            subject.mkdir(mode=0o700)
                    return actual_record(path)
                with patch.object(host, "file_record", side_effect=final_observation), patch.object(host.os, "replace", wraps=os.replace) as replace:
                    with self.assertRaisesRegex(ValueError, "left in situ"):
                        host.replace_subject(subject, b"mock candidate\n", "0644", expected)
                    replace.assert_not_called()
                self.assertTrue(changed)
                self.assertNotEqual(actual_record(subject)[0], expected)
                if mutation == "bytes": self.assertEqual(subject.read_bytes(), b"manual foreign edit\n")
                elif mutation == "mode": self.assertEqual(subject.stat().st_mode & 0o777, 0o600)
                elif mutation == "symlink": self.assertEqual(os.readlink(subject), target.name)
                else: self.assertTrue(subject.is_dir())
                self.assertEqual(target.read_bytes(), b"foreign target, never follow\n")

    def test_finally_unknown_bytes_mode_and_type_stay_in_situ(self):
        for mutation in ["bytes", "mode", "symlink", "directory"]:
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory(dir=HERE) as name:
                folder = Path(name)
                out = folder / "receipt"
                out.mkdir()
                subject = folder / "MOCK_ONLY.gd"
                original, candidate = b"mock original\n", b"mock candidate\n"
                subject.write_bytes(original)
                os.chmod(subject, 0o644)
                original_record = host.file_record(subject)[0]
                host.replace_subject(subject, candidate, "0644", original_record)
                candidate_record = host.file_record(subject)[0]
                target = folder / "FOREIGN_TARGET"
                target.write_bytes(b"foreign target\n")
                if mutation == "bytes": subject.write_bytes(b"foreign after native child\n")
                elif mutation == "mode": os.chmod(subject, 0o600)
                elif mutation == "symlink":
                    subject.unlink()
                    subject.symlink_to(target.name)
                else:
                    subject.unlink()
                    subject.mkdir(mode=0o700)
                before, raw = host.file_record(subject)
                with patch.object(host, "replace_subject", side_effect=AssertionError("must not overwrite unknown subject")):
                    receipt = host.restore_subject_if_known(subject, original, original_record, candidate_record, out, True, True)
                self.assertFalse(receipt["restored_exact_bytes_and_mode"] or receipt["subject_write_attempted"])
                self.assertEqual(receipt["status"], "FAILED_UNKNOWN_SUBJECT_LEFT_IN_SITU")
                self.assertEqual(host.file_record(subject)[0], before)
                if raw is not None:
                    self.assertEqual((out / "unexpected-subject-before-restore.bin").read_bytes(), raw)
                if mutation == "symlink": self.assertEqual(os.readlink(subject), target.name)
                self.assertEqual(target.read_bytes(), b"foreign target\n")

    def test_partial_swap_exact_original_is_noop(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            folder = Path(name)
            subject = folder / "MOCK_ONLY.gd"
            subject.write_bytes(b"mock original\n")
            os.chmod(subject, 0o644)
            record, original = host.file_record(subject)
            candidate_record = dict(record, sha256="b" * 64, bytes=999)
            with patch.object(host, "replace_subject", side_effect=AssertionError("original must not be rewritten")):
                receipt = host.restore_subject_if_known(subject, original, record, candidate_record, folder, True, True)
            self.assertTrue(receipt["restored_exact_bytes_and_mode"])
            self.assertFalse(receipt["subject_write_attempted"])
            self.assertEqual(receipt["status"], "ALREADY_EXACT_ORIGINAL_NO_WRITE")
            self.assertEqual(host.file_record(subject)[0], record)

    def test_known_candidate_restores_but_final_guard_rejects_a_later_edit(self):
        for change_at_guard in [False, True]:
            with self.subTest(change_at_guard=change_at_guard), tempfile.TemporaryDirectory(dir=HERE) as name:
                folder = Path(name)
                subject = folder / "MOCK_ONLY.gd"
                subject.write_bytes(b"mock original\n")
                os.chmod(subject, 0o644)
                original_record, original = host.file_record(subject)
                host.replace_subject(subject, b"mock candidate\n", "0644", original_record)
                candidate_record = host.file_record(subject)[0]
                actual_record, calls = host.file_record, 0
                def observed(path):
                    nonlocal calls
                    if path == subject:
                        calls += 1
                        if change_at_guard and calls == 2:
                            subject.write_bytes(b"manual edit after restore decision\n")
                            os.chmod(subject, 0o600)
                    return actual_record(path)
                with patch.object(host, "file_record", side_effect=observed):
                    receipt = host.restore_subject_if_known(subject, original, original_record, candidate_record, folder, True, True)
                if change_at_guard:
                    self.assertFalse(receipt["restored_exact_bytes_and_mode"])
                    self.assertEqual(receipt["status"], "FAILED_GUARDED_RESTORE_NO_UNKNOWN_WRITE")
                    self.assertEqual(subject.read_bytes(), b"manual edit after restore decision\n")
                    self.assertEqual(subject.stat().st_mode & 0o777, 0o600)
                else:
                    self.assertTrue(receipt["restored_exact_bytes_and_mode"])
                    self.assertEqual(receipt["status"], "RESTORED_KNOWN_CANDIDATE")
                    self.assertEqual(actual_record(subject)[0], original_record)

    def test_open_owned_child_prevents_any_restore_write(self):
        with tempfile.TemporaryDirectory(dir=HERE) as name:
            folder = Path(name)
            subject = folder / "MOCK_ONLY.gd"
            subject.write_bytes(b"mock original\n")
            os.chmod(subject, 0o644)
            original_record, original = host.file_record(subject)
            host.replace_subject(subject, b"mock candidate\n", "0644", original_record)
            candidate_record = host.file_record(subject)[0]
            with patch.object(host, "replace_subject", side_effect=AssertionError("child still open")):
                receipt = host.restore_subject_if_known(subject, original, original_record, candidate_record, folder, False, True)
            self.assertEqual(receipt["status"], "FAILED_OWNED_CHILD_STILL_OPEN_NO_WRITE")
            self.assertFalse(receipt["restored_exact_bytes_and_mode"] or receipt["subject_write_attempted"])
            self.assertEqual(host.file_record(subject)[0], candidate_record)


if __name__ == "__main__":
    output = io.StringIO()
    result = unittest.TextTestRunner(stream=output, verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(HostChecks))
    payload = {"kind": "HOST_ONLY_MOCKED_AND_HISTORICAL_PARSER_TESTS_NOT_NATIVE", "tests": result.testsRun,
               "failures": len(result.failures), "errors": len(result.errors), "success": result.wasSuccessful(),
               "engine_executed": False, "dev_imported": False, "live_subject_mutated": False, "new_measurements": False,
               "historical_raw_scope": "Exact earlier original113 used only to exercise parser/protocol; not this pair's baseline", "output": output.getvalue()}
    (HERE / "HOST_TESTS.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({key: value for key, value in payload.items() if key != "output"}))
    raise SystemExit(0 if result.wasSuccessful() else 1)
