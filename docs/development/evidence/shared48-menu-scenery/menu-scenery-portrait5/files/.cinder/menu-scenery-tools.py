"""Preserve bounded original inputs and run only the new focused menu jobs.

All engine work uses dev.py's canonical runtime, shared queue and owned deadline.
Original output paths are exclusive; import-generated cache/UID outputs are
recorded separately and never inserted into an earlier input manifest.
"""
from pathlib import Path
import datetime, hashlib, importlib.util, json, os, subprocess, sys

ROOT = Path.cwd()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def uid_rows():
    rows = []
    for folder, dirs, files in os.walk(ROOT):
        path = Path(folder)
        if path != ROOT and (path / '.gdignore').exists():
            dirs[:] = []
            continue
        dirs[:] = [x for x in dirs if x not in {
            '.git', '.godot', '.tools', '.cinder', 'captures', 'exports', '__pycache__'
        }]
        for name in files:
            if name.endswith('.uid'):
                source = path / name
                rows.append({'path': str(source.relative_to(ROOT)),
                             'sha256': digest(source), 'uid': source.read_text().strip()})
    return sorted(rows, key=lambda x: x['path'])


def freeze(tag, scope):
    target = ROOT / '.cinder' / (tag + '-source')
    assert not target.exists(), target
    target.mkdir()
    (target / '.gdignore').write_text('\n')
    previous = json.loads((ROOT / '.cinder/a2-l5-production-registration1-source/manifest.json').read_text())
    paths = {row['path'] for row in previous['files']}
    paths.update(row['path'] for row in uid_rows())
    paths.update({
        'scripts/ui/campaign_scenery.gd', 'tests/menu_scenery_smoke.gd',
        '.cinder/menu-scenery-tools.py'
    })
    rows = []
    for relative in sorted(paths):
        source = ROOT / relative
        assert source.is_file(), source
        data = source.read_bytes()
        archived = target / 'files' / relative
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_bytes(data)
        rows.append({'path': relative, 'archived_path': str(archived.relative_to(target)),
                     'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
    manifest = {'schema_version': 1, 'captured_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                'scope': scope, 'files': rows, 'active_uid_before': uid_rows(),
                'coverage': 'Bounded earlier691-input source set plus new scenery/test/driver and current active UID files; not a claimed complete dynamic dependency graph.'}
    path = target / 'manifest.json'
    path.write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({'manifest': str(path.relative_to(ROOT)), 'sha256': digest(path),
                      'source_count': len(rows), 'prior_uid_count': len(manifest['active_uid_before'])}))


def run(tag, mode):
    manifest_path = ROOT / '.cinder' / (tag + '-source/manifest.json')
    manifest = json.loads(manifest_path.read_text())

    def verify(import_outputs=False):
        for row in manifest['files']:
            archive = manifest_path.parent / row['archived_path']
            assert archive.stat().st_size == row['bytes'] and digest(archive) == row['sha256'], archive
            source = ROOT / row['path']
            if import_outputs and row['path'] == '.godot/global_script_class_cache.cfg':
                continue
            assert source.stat().st_size == row['bytes'] and digest(source) == row['sha256'], source

    verify()
    log = ROOT / '.cinder' / (tag + '-wrapper.log')
    result_path = ROOT / '.cinder' / (tag + '-result.json')
    assert not log.exists() and not result_path.exists()
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    command = [sys.executable, '.cinder/menu-scenery-tools.py', 'engine', mode]
    with log.open('xb') as stream:
        child = subprocess.Popen(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        code = child.wait()
    verify(import_outputs=mode == 'import')
    raw = log.read_bytes()
    text = raw.decode('utf-8', 'replace')
    engine_errors = [line for line in text.splitlines() if line.startswith('ERROR:') or 'SCRIPT ERROR' in line or 'Parse Error' in line]
    before = {row['path']: row for row in manifest['active_uid_before']}
    after = {row['path']: row for row in uid_rows()}
    assert all(after.get(path) == row for path, row in before.items())
    assert len({row['uid'] for row in after.values()}) == len(after)
    result = {'started_at': started, 'closed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'command': command, 'child_pid': child.pid, 'returncode': code,
              'source_manifest': str(manifest_path.relative_to(ROOT)), 'source_manifest_sha256': digest(manifest_path),
              'source_count': len(manifest['files']), 'original_archive_current_match': True,
              'wrapper_log': str(log.relative_to(ROOT)), 'wrapper_log_bytes': len(raw),
              'wrapper_log_sha256': hashlib.sha256(raw).hexdigest(),
              'prior_active_uid_count': len(before), 'current_active_uid_count': len(after),
              'all_prior_uid_bytes_retained': True,
              'added_uid_rows': [row for path, row in after.items() if path not in before],
              'collisions': 0, 'engine_error_lines': len(engine_errors), 'scope': manifest['scope'],
              'cache_scope': 'Import may update only the generated global script cache; original pre-import input remains archived.' if mode == 'import' else 'All frozen current inputs match at closure.'}
    result_path.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))
    for line in text.splitlines():
        if any(word in line for word in ['FAIL:', 'SCRIPT ERROR', 'Parse Error', 'checks,']):
            print(line)
    sys.exit(1 if engine_errors or 'FAIL:' in text else code)


def engine(mode):
    spec = importlib.util.spec_from_file_location('cinder_dev', ROOT / 'scripts/dev/dev.py')
    dev = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = dev
    spec.loader.exec_module(dev)
    context = dev.ProjectContext()
    command = [str(dev.resolve_godot(context)), '--path', str(ROOT)]
    if mode == 'import':
        command += ['--headless', '--editor', '--import']
    else:
        if mode in ['native', 'comparison']:
            command += ['--headless']
        script = 'res://tests/replay_comparison_snapshot_smoke.gd' if mode == 'comparison' else 'res://tests/menu_scenery_smoke.gd'
        command += ['--script', script]
        if mode == 'portrait':
            command += ['--', '--capture-portraits']
    with dev.godot_lock(context.root) as lock_fd:
        print('Canonical dev.py queue acquired; owned deadline begins now.', flush=True)
        code = dev.run_validation(command, context, lock_fd, 90, detect_godot_errors=True)
    sys.exit(code)


if __name__ == '__main__':
    if sys.argv[1] == 'freeze':
        freeze(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == 'run':
        run(sys.argv[2], sys.argv[3])
    else:
        assert sys.argv[1] == 'engine' and sys.argv[2] in ['import', 'native', 'portrait', 'comparison']
        engine(sys.argv[2])
