from pathlib import Path
import datetime, hashlib, json, re, stat, subprocess, sys, time

root = Path(__file__).resolve().parent.parent
label, mode, source_path = sys.argv[1:]
assert mode in {'import', 'native', 'portrait'}
source = root / source_path
manifest_path = source / 'manifest.json'
manifest = json.loads(manifest_path.read_text())
assert manifest['variant'] == 'court-art'
log_path = root / '.cinder' / (label + '-wrapper.log')
result_path = root / '.cinder' / (label + '-result.json')
assert not log_path.exists() and not result_path.exists(), 'Never overwrite a job original'

def fingerprint(path):
    p = root / path
    if not p.is_file(): return None
    data = p.read_bytes()
    return {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data),
            'mode': stat.S_IMODE(p.stat().st_mode)}

def mismatch_rows():
    rows = []
    for row in manifest['files']:
        observed = fingerprint(row['path'])
        if observed != {key: row[key] for key in ['sha256', 'bytes', 'mode']}:
            rows.append({'path': row['path'], 'observed': observed})
    return rows

assert not mismatch_rows(), 'Fresh source selection changed before queueing'
script = 'tests/acts/act1/a1_l4_court_art.gd'
command = [sys.executable, 'scripts/dev/dev.py', 'import'] if mode == 'import' else [
    sys.executable, 'scripts/dev/dev.py', 'engine',
    *(['--headless'] if mode == 'native' else []), '--path', '.', '--script', script,
    *(['--', '--portrait'] if mode == 'portrait' else [])]
started_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
started = time.monotonic()
before_sidecars = {p: fingerprint(p + '.uid') for p in [
    'scripts/acts/act1/selenite_court_art.gd',
    'scripts/acts/act1/selenite_court_presented.gd', script]}
print(json.dumps({'label': label, 'mode': mode, 'command': command,
                  'source_files': len(manifest['files']), 'started_at': started_at}), flush=True)
with log_path.open('xb') as stream:
    child = subprocess.Popen(command, cwd=root, stdout=stream, stderr=subprocess.STDOUT)
    code = child.wait()
raw = log_path.read_bytes()
text = raw.decode('utf-8', errors='replace')
footer = re.findall(r'A1-L4 CURTAIN COMPONENT: (\d+) checks, (\d+) failures; (\d+) real swipes, (\d+) ordinary primaries; report=(res://[^;]+);', text)
report_path = root / footer[-1][4].removeprefix('res://') if footer else None
report = json.loads(report_path.read_text()) if report_path is not None and report_path.is_file() else None
errors = [line for line in text.splitlines() if re.match(r'^(?:SCRIPT ERROR|ERROR|WARNING):', line)]
result = {'schema_version': 1, 'label': label, 'mode': mode, 'command': command,
          'checkout': str(root), 'revision': manifest['head'],
          'shared_runtime_publication': manifest['shared_runtime_publication'],
          'started_at': started_at, 'closed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'wall_seconds': time.monotonic() - started, 'exit_code': code,
          'raw_log': str(log_path), 'raw_sha256': hashlib.sha256(raw).hexdigest(),
          'source_archive': str(source), 'source_manifest_sha256': hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
          'frozen_source_files': len(manifest['files']), 'post_run_frozen_member_changes': mismatch_rows(),
          'raw_error_warning_lines': errors, 'explicit_footer': list(footer[-1]) if footer else None,
          'native_report': str(report_path) if report is not None else None,
          'native_report_sha256': hashlib.sha256(report_path.read_bytes()).hexdigest() if report is not None else None,
          'report_checks': report.get('checks') if report is not None else None,
          'report_failures': report.get('failures') if report is not None else None,
          'first_failure': report.get('first_failure') if report is not None else None,
          'captures': report.get('captures', []) if report is not None else [],
          'focus_receipts': report.get('focus_receipts', []) if report is not None else [],
          'new_art_sidecars_before': before_sidecars,
          'new_art_sidecars_after': {p: fingerprint(p + '.uid') for p in before_sidecars},
          'scope': 'Bounded original selection and actual process closure only. Import may legitimately change cache members/generate sidecars; never backfill originals. No complete dependency graph, whole L4, fidelity, human balance or performance claim.'}
result_path.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'result': str(result_path), 'exit_code': code, 'wall_seconds': result['wall_seconds'],
                  'footer': result['explicit_footer'], 'raw_errors_warnings': len(errors),
                  'post_changes': [r['path'] for r in result['post_run_frozen_member_changes']],
                  'captures': len(result['captures'])}), flush=True)
raise SystemExit(code)
