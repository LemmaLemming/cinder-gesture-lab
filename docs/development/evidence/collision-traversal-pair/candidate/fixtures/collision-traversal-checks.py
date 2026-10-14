"""Focused native checks through the existing canonical queue; no source selection."""
from pathlib import Path
import datetime, hashlib, importlib.util, json, os, re, subprocess, sys

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = {
    'differential': '.cinder/collision-traversal-filter/collision_filter_differential.gd',
    'route': 'tests/repulsion_route_smoke.gd',
    'source': 'tests/scheduler_spore_source_smoke.gd',
    'reference': 'tests/scheduler_spore_reference_smoke.gd',
}

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec); sys.modules[name] = result
    spec.loader.exec_module(result); return result

def main():
    action, tag, mode = sys.argv[1:4]
    assert re.fullmatch('[a-z0-9-]+', tag) and mode in SCRIPTS
    target = ROOT / '.cinder/collision-traversal-filter/jobs' / tag
    helper = module(ROOT / '.cinder/collision-signature-profile/tools.py', 'collision_check_helpers')
    if action == 'freeze':
        assert not target.exists()
        todo = [SCRIPTS[mode], '.cinder/collision-traversal-checks.py', '.cinder/collision-signature-profile/tools.py', 'scripts/dev/dev.py', 'project.godot', '.cinder/local.json', '.godot/global_script_class_cache.cfg']
        if mode == 'differential': todo += ['.cinder/collision-traversal-filter/repulsion_route.' + v + '.gd.txt' for v in ['original', 'candidate']]
        seen = set()
        while todo:
            name = todo.pop()
            if name in seen: continue
            p = ROOT / name; assert p.is_file(); seen.add(name)
            if p.suffix in ['.gd', '.tscn', '.tres', '.json', '.txt']:
                todo += [x for x in re.findall(r'res://([^\s"\'\)]+)', p.read_text()) if (ROOT / x).is_file()]
        uids = helper.uids(); seen.update(row['path'] for row in uids)
        target.mkdir(parents=True); (target / '.gdignore').write_bytes(b'')
        rows = []
        for name in sorted(seen):
            p = ROOT / name; q = target / 'source' / name; q.parent.mkdir(parents=True, exist_ok=True)
            q.write_bytes(p.read_bytes()); q.chmod(p.stat().st_mode & 0o777)
            rows.append({'path': name, 'archived_path': str(q.relative_to(target)), 'bytes': p.stat().st_size, 'sha256': sha(p), 'mode': p.stat().st_mode & 0o777})
        manifest = {'mode': mode, 'files': rows, 'uids': uids, 'engine_binary': helper.engine_pin()}
        (target / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
        print(json.dumps({'frozen': tag, 'files': len(rows), 'uids': len(uids)})); return
    manifest = json.loads((target / 'manifest.json').read_text()); assert manifest['mode'] == mode
    helper.verify(target, manifest)
    if action == 'engine':
        dev = helper.dev_module(); context = dev.ProjectContext()
        command = [str(dev.resolve_godot(context)), '--path', str(ROOT), '--headless', '--script', 'res://'+SCRIPTS[mode], '--log-file', str(target / 'raw.log')]
        with dev.godot_lock(context.root) as lock:
            helper.verify(target, manifest)
            print('Canonical queue acquired; own 90 second deadline starts.', flush=True)
            code = dev.run_validation(command, context, lock, 90, detect_godot_errors=True)
        raise SystemExit(code)
    assert action == 'run' and not (target / 'result.json').exists() and not (target / 'wrapper.log').exists()
    with (target / 'wrapper.log').open('xb') as out:
        code = subprocess.call([sys.executable, '-B', str(Path(__file__)), 'engine', tag, mode], cwd=ROOT, stdout=out, stderr=subprocess.STDOUT)
    closure_error = ''
    try: helper.verify(target, manifest)
    except Exception as e: closure_error = str(e)
    raw = (target / 'raw.log').read_text() if (target / 'raw.log').exists() else ''
    combined = raw + '\n' + (target / 'wrapper.log').read_text()
    bad = re.findall(r'(?m)^ERROR:|^WARNING:|SCRIPT ERROR|Parse Error|Compile Error|FAIL:|leaked|unclaimed', combined)
    footers = re.findall(r'(\d+) checks, (\d+) failures', raw)
    success = code == 0 and not bad and not closure_error and len(footers) == 1 and int(footers[0][1]) == 0
    result = {'closed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'mode': mode, 'returncode': code, 'successful_scope': success, 'diagnostics': bad, 'footers': footers, 'closure_error': closure_error, 'input_count': len(manifest['files']), 'uids': len(manifest['uids']), 'manifest_sha256': sha(target / 'manifest.json'), 'streams': {n: sha(target/n) for n in ['raw.log', 'wrapper.log'] if (target/n).exists()}, 'scope': 'Bounded explicit/literal resource sources and all active UID bytes; focused named native check only. No campaign acceptance or performance credit.'}
    (target / 'result.json').write_text(json.dumps(result, indent=2)+'\n'); print(json.dumps(result))
    raise SystemExit(0 if success else 1)

if __name__ == '__main__': main()
