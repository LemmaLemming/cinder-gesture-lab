#!/usr/bin/env python3
"""Archive explicit CLOSED L5 run folders only. No engine/Git/import/lock action.
Default is read-only verification. --apply copies new archives and an optional
selection index; an existing archive is verified and never modified.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ARCHIVE_REL = Path('docs/acts/act1/evidence/A1-L5-difficulty')
RUN_REL = Path('.cinder/l5-difficulty')
SCOPE = 'Only explicitly selected closed L5 jobs. Original run trees and recorded native shot/branch companion bytes retained; no current-runtime equality, global dependency census, new test execution or visual-review claim.'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def read_json(path):
    return json.loads(path.read_bytes())

def file_info(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': sha(data)}

def safe_relative(value):
    p = Path(value)
    if p.is_absolute() or '..' in p.parts:
        raise ValueError('unsafe relative archive member: ' + str(value))
    return p

def members(directory):
    # This is an inventory of one explicit run/archive subtree, not the repo.
    result = {}
    for path in sorted(directory.rglob('*')):
        if path.is_symlink():
            raise ValueError('symlink requires explicit handling, refusing: ' + str(path))
        if path.is_file(): result[str(path.relative_to(directory))] = file_info(path)
    return result

def verify_recorded_files(run, receipt):
    checked = []
    for filename, key in [('raw.log', 'raw_sha256'), ('source-pre.json', 'source_pre_manifest_sha256'),
                          ('source-post.json', 'source_post_manifest_sha256'), ('native.json', 'native_report_sha256')]:
        if key not in receipt:
            continue  # Missing native output is preserved as incomplete, never fabricated.
        path = run / filename
        if not path.is_file() or file_info(path)['sha256'] != receipt[key]:
            raise ValueError('recorded file/hash mismatch: ' + str(path))
        checked.append(filename)
    for phase in ('pre', 'post'):
        manifest = run / ('source-' + phase + '.json')
        if not manifest.is_file(): continue
        for row in read_json(manifest).get('files', []):
            bank = run / ('source-' + phase) / safe_relative(row['bank_path'])
            if row.get('exists'):
                if not bank.is_file() or file_info(bank) != {'bytes': row['bytes'], 'sha256': row['sha256']}:
                    raise ValueError('source bank does not match its original manifest: ' + str(bank))
            elif bank.exists():
                raise ValueError('originally absent source unexpectedly has bank bytes: ' + str(bank))
    return checked

def resolve_report_path(root, value):
    return (root / value[6:]).resolve() if value.startswith('res://') else (root / value).resolve()

def pointer_token(value):
    return value.replace('~', '~0').replace('/', '~1')

def single_name(value):
    if not isinstance(value, str) or not value or value in ('.', '..') or '/' in value or chr(92) in value:
        raise ValueError('branch label/member must be one literal name: ' + repr(value))
    return value

def inspect_companions(root, native):
    result = []; errors = []
    branches = native.get('branches', {})
    if not isinstance(branches, dict):
        return result, ['native /branches is not a dictionary; no companion copies selected']
    artifact_value = native.get('artifact_root')
    artifact_root = resolve_report_path(root, artifact_value) if isinstance(artifact_value, str) and artifact_value else None
    def inspect_one(label, name, recorded, pointer, branch_row=None):
        item = {'native_pointer': pointer, 'branch_label': label, 'member': name, 'verified': False}
        try:
            single_name(label); single_name(name)
            item['archive_path'] = 'branches/' + label + '/' + name
            if not isinstance(recorded, dict) or not isinstance(recorded.get('path'), str):
                raise ValueError('missing original companion path')
            item['literal_path'] = recorded['path']
            original = resolve_report_path(root, recorded['path'])
            item['original_path'] = str(original)
            if artifact_root is None or not artifact_root.is_relative_to((root / '.cinder').resolve()) or artifact_root == (root / '.cinder').resolve():
                raise ValueError('actual artifact_root must be a child of this checkout .cinder')
            if original != artifact_root / label / name:
                raise ValueError('original companion path does not match actual artifact_root/label/name')
            # Refuse symbolic files/directories, including a path which resolves elsewhere.
            literal = root / recorded['path'][6:] if recorded['path'].startswith('res://') else root / recorded['path']
            if any(x.is_symlink() for x in [literal, *literal.parents] if x != root.parent):
                raise ValueError('symlink in original companion path')
            if not original.is_file(): raise ValueError('original companion file is missing; no bytes reconstructed from hex')
            data = original.read_bytes()
            item.update(bytes=len(data), sha256=sha(data))
            if branch_row is not None:
                if json.loads(data) != branch_row: raise ValueError('original branch.json differs from literal native branch row')
            else:
                for key in ('bytes', 'sha256', 'hex'): item['recorded_' + key if key != 'hex' else 'recorded_hex_present'] = recorded.get(key) if key != 'hex' else isinstance(recorded.get(key), str)
                if type(recorded.get('bytes')) is not int or recorded['bytes'] != len(data): raise ValueError('original companion byte count differs')
                if recorded.get('sha256') != sha(data): raise ValueError('original companion SHA256 differs')
                if not isinstance(recorded.get('hex'), str) or recorded['hex'] != data.hex(): raise ValueError('original companion literal hex differs')
            item['verified'] = True
        except (OSError, ValueError, TypeError) as exc:
            item['archival_error'] = str(exc); errors.append(pointer + ': ' + str(exc))
        result.append(item)
    for label, row in branches.items():
        pointer = '/branches/' + pointer_token(label)
        if not isinstance(row, dict) or row.get('label') != label or not isinstance(row.get('all_original_disk_files'), dict):
            errors.append(pointer + ': invalid literal branch row/files; no companion copies selected'); continue
        files = row['all_original_disk_files']
        if not files: errors.append(pointer + ': all_original_disk_files is empty')
        if 'campaign.json' not in files or row.get('raw_store') != files.get('campaign.json'):
            errors.append(pointer + ': raw_store does not equal original campaign.json record')
        for name, record in files.items():
            inspect_one(label, name, record, pointer + '/all_original_disk_files/' + pointer_token(name))
        if 'branch.json' in files:
            errors.append(pointer + ': branch.json collides with reserved original branch receipt')
        elif artifact_root is not None:
            inspect_one(label, 'branch.json', {'path': str(artifact_root / label / 'branch.json')}, pointer, row)
        else:
            errors.append(pointer + ': original branch.json location unavailable without artifact_root')
    return result, errors

def inspect_run(root, run):
    receipt = read_json(run / 'receipt.json')
    if receipt.get('state') != 'closed' or not receipt.get('closed_at') or 'exit_code' not in receipt:
        raise ValueError('not a closed run/launch result; no archive action: ' + str(run))
    if Path(receipt.get('run_directory', str(run))).resolve() != run:
        raise ValueError('receipt points to another run directory: ' + str(run))
    verified = verify_recorded_files(run, receipt)
    native_path = run / 'native.json'
    native_error = None
    try:
        native = read_json(native_path) if native_path.is_file() else {}
        if not isinstance(native, dict): raise ValueError('native report is not a JSON object')
    except (ValueError, UnicodeDecodeError) as exc:
        native = {}; native_error = str(exc)  # Retain malformed native bytes as incomplete evidence.
    shots = []
    for i, row in enumerate(native.get('shots', [])):
        if not isinstance(row, dict) or not isinstance(row.get('path'), str):
            raise ValueError('native shot lacks its literal original path')
        original = resolve_report_path(root, row['path'])
        if not original.is_relative_to((root / '.cinder').resolve()):
            raise ValueError('shot path outside checkout .cinder: ' + str(original))
        item = {'native_pointer': '/shots/' + str(i), 'literal_path': row['path'], 'reported_sha256': row.get('sha256'), 'recorded_personal_review': row.get('personal_review'), 'original_path': str(original),
                'archive_path': 'shots/%02d-%s' % (i + 1, original.name), 'exists': original.is_file()}
        if item['exists']:
            data = original.read_bytes()
            if not data.startswith(b'\x89PNG\r\n\x1a\n'):
                raise ValueError('recorded shot is not an actual PNG: ' + str(original))
            item.update(bytes=len(data), sha256=sha(data))
            if row.get('sha256') is not None and row['sha256'] != item['sha256']:
                raise ValueError('recorded shot hash mismatch: ' + str(original))
        else:
            item['limitation'] = 'Recorded PNG absent at archival inspection; no replacement generated.'
        shots.append(item)
    companions, archival_errors = inspect_companions(root, native)
    tree = members(run)
    if 'archive-verification.json' in tree:
        raise ValueError('run contains reserved archive-verification.json; choose explicit alternate archival handling')
    for item in companions:
        if item.get('archive_path') in tree:
            raise ValueError('original run member collides with reserved companion destination: ' + item['archive_path'])
    destination = root / ARCHIVE_REL / run.name
    first = native.get('first_failure', receipt.get('first_failure'))
    row = {'run': run.name, 'original_directory': str(run), 'archive_directory': str(destination),
           'receipt_sha256': tree['receipt.json']['sha256'], 'command': receipt.get('command'),
           'fixture_arguments': receipt.get('fixture_arguments'), 'started_at': receipt.get('started_at'),
           'closed_at': receipt.get('closed_at'), 'exit_code': receipt.get('exit_code'),
           'recorded_result': receipt.get('result'), 'subprocess_started': receipt.get('subprocess_started'),
           'runner_error': receipt.get('runner_error'), 'report_error': receipt.get('report_error'),
           'recorded_assertion_evidence': receipt.get('assertion_evidence'),
           'source_api_declarations': receipt.get('source_api_declarations', []),
           'git_before': receipt.get('git_before'), 'git_at_native_banner': receipt.get('git_at_native_banner'),
           'git_after': receipt.get('git_after'),
           'literal_native_scope': native.get('scope'), 'checks': native.get('checks', receipt.get('native_checks')),
           'failures': native.get('failures', receipt.get('native_failures')),
           'scope_complete': native.get('scope_complete', native.get('complete', receipt.get('native_completion_flag'))),
           'native_success': native.get('success'), 'native_parse_error': native_error, 'case': native.get('case', receipt.get('native_case')),
           'first_failure_label': first.get('label') if isinstance(first, dict) else None,
           'first_failure_pointer': 'native.json#/first_failure' if native_path.is_file() else 'receipt.json#/first_failure',
           'wall_seconds': receipt.get('wall_seconds'), 'native_elapsed_ms': native.get('elapsed_ms', native.get('wall_ms', receipt.get('native_elapsed_ms'))),
           'queue_observations': receipt.get('queue_observations', []),
           'queue_message_to_banner_observed_s': receipt.get('queue_message_to_banner_observed_s'),
           'raw_error_warning_lines': receipt.get('raw_error_warning_lines', []),
           'recorded_source_changes_at_banner': receipt.get('selected_input_changes_at_banner'),
           'recorded_source_changes_after': receipt.get('selected_input_changes'),
           'source_pre_manifest_sha256': tree.get('source-pre.json', {}).get('sha256'),
           'source_post_manifest_sha256': tree.get('source-post.json', {}).get('sha256'),
           'native_report_sha256': tree.get('native.json', {}).get('sha256'),
           'literal_native_report_original': receipt.get('native_report_original'),
           'literal_source_reports': [{'native_pointer': '/source_reports/' + str(i), **{k: r[k] for k in ('path', 'kind', 'sha256', 'receipt_label', 'wire_sha256', 'snapshot_sha256', 'attempts_sha256', 'checks', 'failures') if k in r}} for i, r in enumerate(native.get('source_reports', [])) if isinstance(r, dict)],
           'literal_report_arguments': receipt.get('report_arguments', []),
           'native_receipt_labels': [r.get('label', r.get('stage')) for r in native.get('receipts', []) if isinstance(r, dict)],
           'companions': companions, 'archival_errors': archival_errors, 'archival_complete': not archival_errors,
           'original_files': tree, 'recorded_hash_files_verified': verified, 'shots': shots, 'scope': SCOPE, 'archiver_evaluated_gameplay_or_pixels': False}
    return row

def verify_archive(row, destination):
    # Preserve pre-existing diagnoses/extra archival metadata without rewriting it.
    existing = members(destination)
    for path, expected in row['original_files'].items():
        if existing.get(path) != expected:
            raise ValueError('existing archive differs/misses original; refusing overwrite: ' + str(destination / path))
    for shot in row['shots']:
        if shot['exists'] and existing.get(shot['archive_path']) != {'bytes': shot['bytes'], 'sha256': shot['sha256']}:
            raise ValueError('existing archive lacks/differs from recorded shot; refusing modification: ' + str(destination / shot['archive_path']))
    for companion in row['companions']:
        if companion['verified'] and existing.get(companion['archive_path']) != {'bytes': companion['bytes'], 'sha256': companion['sha256']}:
            raise ValueError('existing archive lacks/differs from original companion; refusing modification: ' + str(destination / companion['archive_path']))
    return sorted(set(existing) - set(row['original_files']) - {s['archive_path'] for s in row['shots'] if s['exists']} - {c['archive_path'] for c in row['companions'] if c['verified']})

def copy_new(row):
    source = Path(row['original_directory']); dest = Path(row['archive_directory'])
    dest.mkdir(parents=True, exist_ok=False)
    for relative, expected in row['original_files'].items():
        data = (source / relative).read_bytes()
        if {'bytes': len(data), 'sha256': sha(data)} != expected:
            raise ValueError('closed original changed before copy: ' + str(source / relative))
        target = dest / safe_relative(relative); target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as f: f.write(data)
    for shot in row['shots']:
        if not shot['exists']: continue
        data = Path(shot['original_path']).read_bytes()
        if sha(data) != shot['sha256']: raise ValueError('shot changed during copy')
        target = dest / safe_relative(shot['archive_path']); target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as f: f.write(data)
    for companion in row['companions']:
        if not companion['verified']: continue
        data = Path(companion['original_path']).read_bytes()
        if {'bytes': len(data), 'sha256': sha(data)} != {'bytes': companion['bytes'], 'sha256': companion['sha256']}:
            raise ValueError('original companion changed before copy; retain partial archive for investigation')
        target = dest / safe_relative(companion['archive_path']); target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as f: f.write(data)
    if members(source) != row['original_files']:
        raise ValueError('closed source run changed during archive; retain partial copy for investigation')
    verify_archive(row, dest)
    # New archives only. All source files retain their original bytes and paths.
    with (dest / 'archive-verification.json').open('x') as f:
        json.dump(row, f, indent=2); f.write('\n')

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', required=True, type=Path)
    p.add_argument('--run', action='append', required=True, help='Explicit basename or path under .cinder/l5-difficulty; repeatable')
    p.add_argument('--apply', action='store_true', help='Copy new archives; otherwise verify/read only')
    p.add_argument('--index-output', type=Path, help='Optional new deterministic selection-index JSON; never overwritten')
    args = p.parse_args(); root = args.root.resolve(); runs = []
    for value in args.run:
        candidate = Path(value)
        run = (root / RUN_REL / candidate if len(candidate.parts) == 1 else root / candidate).resolve()
        if not run.is_relative_to((root / RUN_REL).resolve()) or run == (root / RUN_REL).resolve():
            p.error('run must be an explicit child beneath .cinder/l5-difficulty')
        if run in runs or any(x.name == run.name for x in runs): p.error('duplicate run/archive basename')
        runs.append(run)
    # Validate every requested closure before writing any archive.
    rows = [inspect_run(root, run) for run in runs]
    for row in rows:
        dest = Path(row['archive_directory'])
        if dest.exists():
            extras = verify_archive(row, dest)
            print(json.dumps({'run': row['run'], 'action': 'verified_existing_untouched', 'preserved_extra_files': extras}))
        elif args.apply:
            copy_new(row); print(json.dumps({'run': row['run'], 'action': 'copied_verified' if row['archival_complete'] else 'copied_with_archival_errors'}))
        else:
            print(json.dumps({'run': row['run'], 'action': 'verified_closed_ready_to_copy' if row['archival_complete'] else 'verified_closed_with_archival_errors'}))
    for row in rows:
        for error in row['archival_errors']: print('Archival error [' + row['run'] + ']: ' + error, file=sys.stderr)
    summaries = []
    for row in rows:
        summary = {k: v for k, v in row.items() if k != 'original_files'}
        summary['original_file_count'] = len(row['original_files'])
        summary['verified_original_inventory_sha256'] = sha(json.dumps(row['original_files'], sort_keys=True, separators=(',', ':')).encode())
        summaries.append(summary)
    index = {'scope': SCOPE, 'runs': summaries}
    if args.index_output:
        data = (json.dumps(index, indent=2) + '\n').encode()
        target = args.index_output.resolve()
        if any(target.is_relative_to(Path(row[k])) for row in rows for k in ('original_directory', 'archive_directory')):
            raise ValueError('selection index must be outside every selected original/archive run tree')
        if target.exists():
            if target.read_bytes() != data: raise ValueError('existing selection index differs; choose a new explicit path')
        elif args.apply:
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open('xb') as f: f.write(data)
        print(json.dumps({'index_output': str(target), 'sha256': sha(data), 'written_or_already_exact': target.is_file()}))
    return 1 if any(row['archival_errors'] for row in rows) else 0

if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print('Archive verification stopped: ' + str(exc), file=sys.stderr)
        raise SystemExit(1)
