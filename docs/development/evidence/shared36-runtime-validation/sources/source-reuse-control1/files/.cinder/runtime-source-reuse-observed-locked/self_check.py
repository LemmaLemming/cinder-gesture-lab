"""Python-only fake-child ordering checks. No Godot, real lock or live writes."""
from pathlib import Path
import ast
import contextlib
import hashlib
import importlib.util
import json
import shutil
import stat
import types


DIRECTORY = Path(__file__).resolve().parent
ROOT = DIRECTORY.parent.parent


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def load_runner():
    path = DIRECTORY / 'run_controlled_fixture.py'
    raw = path.read_bytes()
    ast.parse(raw)
    namespace = {'__file__': str(path), '__name__': 'offline_order_probe'}
    exec(compile(raw, str(path), 'exec'), namespace)
    return namespace


def check_case(kind, fixture):
    ns = load_runner()
    path = ROOT / 'scripts/dev/dev.py'
    dev = ns['load_actual_dev'](ROOT, {'bytes': path.stat().st_size, 'sha256': sha(path.read_bytes())})
    catalogue = fixture / 'catalogue.json'
    original = b'{"synthetic_only":true}\n'
    catalogue.write_bytes(original)
    catalogue.chmod(0o640)
    events, held, child = [], [False], [None]
    ns['verify_release'] = lambda *_: events.append('preflight_under_lock')
    actual_restore = ns['restore_exact']

    def restore(path, raw, mode):
        assert held[0] and child[0].poll() is not None
        events.append('restore_after_child_close_while_held')
        actual_restore(path, raw, mode)

    ns['restore_exact'] = restore

    @contextlib.contextmanager
    def fake_lock(_root):
        # A disposable descriptor only, NOT a flock or canonical engine lock.
        with (fixture / 'descriptor-only').open('wb') as stream:
            held[0] = True
            events.append('dev_main_lock_enter')
            try:
                yield stream.fileno()
            finally:
                assert catalogue.read_bytes() == original
                assert stat.S_IMODE(catalogue.stat().st_mode) == 0o640
                events.append('dev_main_lock_exit_after_exact_restore')
                held[0] = False

    class FakeChild:
        pid = 123  # Synthetic identifier; never emitted as a native receipt.
        returncode = None

        def __init__(self, command, **kwargs):
            assert held[0] and kwargs['pass_fds'] and kwargs['cwd'] == fixture
            events.append('original_run_child_created_fake_child')
            self.calls = 0
            child[0] = self

        def poll(self):
            return self.returncode

        def wait(self):
            self.calls += 1
            assert held[0]
            if kind != 'mode_only':
                catalogue.write_bytes(b'{"synthetic_changed":true}\n')
            catalogue.chmod(0o600)
            if kind == 'unexpected_wait_exception' and self.calls == 1:
                events.append('first_wait_exception_child_still_live')
                raise KeyboardInterrupt()
            if kind == 'dev_caught_oserror' and self.calls == 1:
                events.append('first_wait_oserror_child_still_live')
                raise OSError('synthetic wait error')
            if kind == 'propagated_runtime_error' and self.calls == 1:
                events.append('first_wait_runtimeerror_child_still_live')
                raise RuntimeError('synthetic wait error')
            self.returncode = 7 if kind == 'nonzero_child' else 0
            events.append('original_fake_child_closed')
            return self.returncode

    actual_popen = dev.subprocess.Popen
    dev.ProjectContext = lambda: types.SimpleNamespace(root=fixture, environ={})
    dev.resolve_godot = lambda _: Path('/SYNTHETIC_ONLY_NOT_EXECUTED')
    dev.godot_lock = fake_lock
    dev.subprocess.Popen = FakeChild
    receipt = {'lock_entered': False}
    error = None
    try:
        try:
            result = ns['invoke_locked'](dev, ['engine', '--headless'], fixture, fixture,
                                         {'catalogue_base': {'path': 'catalogue.json', 'bytes': len(original), 'sha256': sha(original)}}, receipt)
        except RuntimeError as exc:
            assert kind == 'propagated_runtime_error'
            result, error = None, str(exc)
    finally:
        dev.subprocess.Popen = actual_popen
    assert result == {'nonzero_child': 7, 'unexpected_wait_exception': 130, 'mode_only': 0,
                      'dev_caught_oserror': 2, 'propagated_runtime_error': None}[kind]
    assert receipt['actual_child_exit'] == (7 if kind == 'nonzero_child' else 0)
    assert receipt['restored_catalogue']['while_canonical_lock_held']
    assert events.index('original_fake_child_closed') < events.index('restore_after_child_close_while_held')
    assert events[-1] == 'dev_main_lock_exit_after_exact_restore'
    return {'control': kind, 'fake_dev_main_exit': result, 'fake_child_exit': receipt['actual_child_exit'],
            'propagated_exception': error, 'events': events,
            'bytes_and_mode_restored': True, 'native_process_started': False, 'real_lock_acquired': False}


def main():
    fixture = DIRECTORY / '.self-check-disposable'
    if fixture.exists():
        raise RuntimeError('Refuse an existing synthetic fixture')
    fixture.mkdir()
    try:
        cases = [check_case(kind, fixture) for kind in ('nonzero_child', 'unexpected_wait_exception',
                                                      'dev_caught_oserror', 'propagated_runtime_error', 'mode_only')]
    finally:
        shutil.rmtree(fixture)
    report = {'scope': 'Python fake-child tests against actual imported dev.main/run_child bodies; canonical godot_lock and native Popen replaced ONLY in this synthetic process',
              'cases': cases, 'native_jobs_started': 0, 'canonical_catalogue_writes': 0,
              'limitation': 'Does not execute GDScript/Godot, acquire a real lock, or guarantee hard-termination recovery'}
    (DIRECTORY / 'self-check.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
