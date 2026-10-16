#!/usr/bin/env python3
"""Archive the CLOSED old-east01 O1 consumer run; no engine, Git or deletion.
Without --apply: inspect and print a plan, writing nothing anywhere.
With --apply: create a NEW portable archive, never overwrite an existing one.
"""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import stat
import sys

RUN_BASE = Path('.cinder/o1-difficulty')
ARCHIVE_BASE = Path('docs/acts/act1/evidence/A1-O1-difficulty')
MANIFEST = 'archive-manifest.json'
MANIFEST_SHA = 'archive-manifest.sha256'
SCOPE = ('Exact copies of the CLOSED old-east01 O1 consumer run, original emitted native report, '
         'and already banked selected inputs. Preserve the failed 60-check/1-failure result literally. '
         'Do not expand native donor branch rows, reconstruct files, retry gameplay, or claim global closure.')
PRODUCER_ARCHIVER_REJECTION = (
    'Frozen producer archiver c076407f requires every branch companion path to match '
    'native.branch_root/label/name. In this consumer, branch_root is an unused fresh '
    'default while branches[one-part-live] is the literal input producer row with '
    'original producer-root companion paths. Re-expanding it under the consumer '
    'root would invent custody. This consumer archiver leaves both literal fields '
    'unchanged and preserves the already banked producer report plus three raw input '
    'files; the separate legacy-producer01 archive retains original donor branches.')



def digest(data):
    return hashlib.sha256(data).hexdigest()


def json_bytes(value):
    return (json.dumps(value, indent=2, sort_keys=True) + '\n').encode('utf-8')


def relative(value):
    if not isinstance(value, str) or not value or '\\' in value:
        raise ValueError('invalid relative member: ' + repr(value))
    p = Path(value)
    if p.is_absolute() or '..' in p.parts or p == Path('.'):
        raise ValueError('unsafe relative member: ' + value)
    return p


def single_name(value):
    p = relative(value)
    if len(p.parts) != 1 or value in ('.', '..'):
        raise ValueError('expected one literal run/branch/file name: ' + value)
    return value


def no_symlinks(path, boundary):
    if not path.is_relative_to(boundary):
        raise ValueError('path escapes its allowed root: ' + str(path))
    for part in [path, *path.parents]:
        if part.is_symlink():
            raise ValueError('symlink refused: ' + str(part))
        if part == boundary:
            break


def info(path):
    st = path.lstat()
    if not stat.S_ISREG(st.st_mode):
        raise ValueError('regular original file required: ' + str(path))
    data = path.read_bytes()
    after = path.lstat()
    if (st.st_ino, st.st_size, st.st_mtime_ns, st.st_mode) != (after.st_ino, after.st_size, after.st_mtime_ns, after.st_mode):
        raise ValueError('original changed while reading: ' + str(path))
    return {'bytes': len(data), 'sha256': digest(data), 'mode': stat.S_IMODE(st.st_mode)}


def inventory(directory):
    files, dirs = {}, {'.': stat.S_IMODE(directory.lstat().st_mode)}
    if not stat.S_ISDIR(directory.lstat().st_mode):
        raise ValueError('ordinary directory required: ' + str(directory))
    for here, children, names in os.walk(directory, followlinks=False):
        parent = Path(here)
        for name in sorted(children):
            child = parent / name
            if not stat.S_ISDIR(child.lstat().st_mode):
                raise ValueError('symlink or non-directory refused: ' + str(child))
            dirs[child.relative_to(directory).as_posix()] = stat.S_IMODE(child.lstat().st_mode)
        for name in sorted(names):
            child = parent / name
            files[child.relative_to(directory).as_posix()] = info(child)
    return {'files': files, 'directories': dirs}


def read_object(path):
    value = json.loads(path.read_bytes())
    if not isinstance(value, dict):
        raise ValueError('JSON object required: ' + str(path))
    return value


def original_path(root, literal):
    if not isinstance(literal, str) or not literal:
        raise ValueError('literal original path missing')
    if literal.startswith('res://'):
        p = root / relative(literal[6:])
    elif Path(literal).is_absolute():
        p = Path(literal)
    else:
        p = root / relative(literal)
    # Do not resolve through a symbolic link before checking it.
    no_symlinks(p, root / '.cinder')
    if not p.is_file():
        raise ValueError('original file missing; never reconstruct from hex: ' + str(p))
    return p


def verify_recorded_run(run, receipt):
    for name, key in [('raw.log', 'raw_sha256'), ('source-pre.json', 'source_pre_manifest_sha256'),
                      ('source-post.json', 'source_post_manifest_sha256')]:
        if not isinstance(receipt.get(key), str) or info(run / name)['sha256'] != receipt[key]:
            raise ValueError('original receipt hash mismatch/missing: ' + name)
    for phase in ('pre', 'post'):
        manifest = read_object(run / ('source-' + phase + '.json'))
        if not isinstance(manifest.get('files'), list):
            raise ValueError('original source manifest lacks files: ' + phase)
        seen = set()
        for row in manifest['files']:
            key = relative(row['bank_path']).as_posix()
            if key in seen:
                raise ValueError('duplicate source bank member: ' + key)
            seen.add(key)
            bank = run / ('source-' + phase) / key
            if row.get('exists') is True:
                got = info(bank)
                if got['bytes'] != row.get('bytes') or got['sha256'] != row.get('sha256'):
                    raise ValueError('original source-bank bytes disagree: ' + str(bank))
            elif row.get('exists') is not False or bank.exists():
                raise ValueError('original absent source bank is incoherent: ' + str(bank))


def inspect(root, name):
    run = root / RUN_BASE / single_name(name)
    destination = root / ARCHIVE_BASE / name
    no_symlinks(run, root)
    no_symlinks(destination, root)
    if destination.exists():
        raise ValueError('archive already exists; never overwrite or modify: ' + str(destination))
    original_tree = inventory(run)
    for reserved in (MANIFEST, MANIFEST_SHA):
        if reserved in original_tree['files'] or reserved in original_tree['directories']:
            raise ValueError('original run collides with reserved manifest name: ' + reserved)
    receipt = read_object(run / 'receipt.json')
    if receipt.get('state') != 'closed' or not isinstance(receipt.get('closed_at'), str) or not receipt['closed_at'] or 'exit_code' not in receipt:
        raise ValueError('only an actually CLOSED recorded result can be archived')
    if receipt.get('run_directory') != str(run) or receipt.get('checkout') != str(root):
        raise ValueError('receipt checkout/run identity differs from selected original')
    verify_recorded_run(run, receipt)
    copies = {}
    directories = original_tree['directories'].copy()

    def add(source, target, reference):
        key = relative(target).as_posix()
        if key in (MANIFEST, MANIFEST_SHA) or key in directories:
            raise ValueError('archive file/directory collision: ' + key)
        details = info(source)
        if key in copies:
            if copies[key]['expected'] != details:
                raise ValueError('two originals differ in bytes/mode at one destination: ' + key)
            copies[key]['origins'].append({'path': str(source), 'reference': reference})
        else:
            copies[key] = {'expected': details, 'origins': [{'path': str(source), 'reference': reference}]}
        parent = Path(key).parent
        while parent != Path('.'):
            if parent.as_posix() in copies:
                raise ValueError('archive parent collides with file: ' + str(parent))
            directories.setdefault(parent.as_posix(), 0o755)
            parent = parent.parent

    for key in original_tree['files']:
        add(run / key, key, 'original run subtree/' + key)
    native = {}
    native_parse_error = None
    native_original = receipt.get('native_report_original')
    if not isinstance(native_original, str) or not native_original or not isinstance(receipt.get('native_report_sha256'), str):
        raise ValueError('consumer requires the literal emitted native report and receipt hash')
    if native_original is not None:
        path = original_path(root, native_original)
        details = info(path)
        recorded = receipt.get('native_report_sha256')
        if recorded is not None and details['sha256'] != recorded:
            raise ValueError('literal original native report differs from receipt hash')
        add(path, 'native.json', 'receipt.native_report_original')
        try:
            native = read_object(path)
        except (ValueError, UnicodeDecodeError) as exc:
            native_parse_error = str(exc)  # Copy malformed original bytes without reclassifying the run.
    elif 'native.json' in copies:
        # Keep exact run bytes, but do not invent receipt authority or replacement.
        try:
            native = read_object(run / 'native.json')
        except (ValueError, UnicodeDecodeError) as exc:
            native_parse_error = str(exc)

    if native_parse_error is not None:
        raise ValueError('scoped consumer native report must parse without reconstruction: ' + native_parse_error)
    if receipt.get('requested_case') != 'old-east-second' or native.get('case') != 'old-east-second':
        raise ValueError('only the original old-east-second consumer result is in scope')
    if native.get('checks') != 60 or native.get('failures') != 1 or native.get('success') is not False or native.get('complete') is not False or receipt.get('exit_code') != 1:
        raise ValueError('expected literal closed 60-check/1-failure exit1 result; never relabel another run')
    branches = native.get('branches', {})
    if not isinstance(branches, dict):
        raise ValueError('literal native branches has invalid type')
    # These are INPUT provenance, not new consumer-produced branch directories.
    # Do not dereference/expand branch_root or any donor companion path here.
    branch_note = {
        'mode': 'literal_input_branch_rows_not_expanded',
        'native_branch_root_preserved': native.get('branch_root'),
        'native_branch_labels_preserved': list(branches),
        'separate_producer_archive': str(root / ARCHIVE_BASE / 'legacy-producer01'),
        'producer_archiver_rejection': PRODUCER_ARCHIVER_REJECTION,
    }
    input_rows = receipt.get('input_arguments')
    if not isinstance(input_rows, list) or len(input_rows) != 4:
        raise ValueError('exact four already banked producer-report/raw-file inputs required')
    banked_inputs = []
    seen_inputs = set()
    required_flags = {'--source-producer-report', '--source-branch-store', '--source-backup-store', '--source-preferences-store'}
    seen_flags = set()
    manifests = {phase: read_object(run / ('source-' + phase + '.json')) for phase in ('pre', 'post')}
    for row in input_rows:
        if not isinstance(row, dict) or row.get('role') != 'source_input' or row.get('exists_before') is not True or not isinstance(row.get('path'), str) or not isinstance(row.get('argument'), str):
            raise ValueError('complete literal source-input provenance required')
        flag = row['argument'].split('=', 1)[0]
        if flag not in required_flags or flag in seen_flags or row['path'] in seen_inputs:
            raise ValueError('unknown or duplicate consumer source input')
        seen_flags.add(flag); seen_inputs.add(row['path'])
        item = {'argument': row['argument'], 'original_input_path': row['path'], 'role': 'input_only', 'banks': {}}
        for phase, manifest in manifests.items():
            matches = [entry for entry in manifest['files'] if entry.get('path') == row['path']]
            if len(matches) != 1 or matches[0].get('exists') is not True:
                raise ValueError('literal consumer input must exist in each exact source bank')
            entry = matches[0]
            item['banks'][phase] = {'archive_path': 'source-' + phase + '/' + relative(entry['bank_path']).as_posix(), 'sha256': entry['sha256'], 'bytes': entry['bytes']}
        banked_inputs.append(item)
    for key in copies:
        if key in directories:
            raise ValueError('final archive file/directory collision: ' + key)
    return {
        'api_revision': 'act1-o1-consumer-run-archive-1', 'scope': SCOPE,
        'created_at': dt.datetime.now(dt.timezone.utc).isoformat(), 'run': name,
        'original_directory': str(run), 'archive_directory': str(destination),
        'receipt_sha256': original_tree['files']['receipt.json']['sha256'],
        'recorded_result': receipt.get('result'), 'recorded_state': receipt['state'],
        'recorded_exit_code': receipt['exit_code'], 'recorded_closed_at': receipt['closed_at'],
        'recorded_command': receipt.get('command'), 'recorded_requested_case': receipt.get('requested_case'),
        'recorded_source_attribution': {key: receipt.get(key) for key in (
            'git_before', 'git_at_native_banner', 'git_after', 'source_api_declarations',
            'source_pre_manifest_sha256', 'source_post_manifest_sha256',
            'selected_input_changes_at_banner', 'selected_input_changes')},
        'literal_native_report_original': native_original, 'native_parse_error': native_parse_error,
        'native_observed_fields': {key: native.get(key) for key in ('case', 'checks', 'failures', 'complete', 'scope_complete', 'success')},
        'native_first_failure_label': native.get('first_failure', {}).get('label'),
        'native_first_failure_json_sha256': digest(json_bytes(native.get('first_failure'))),
        'native_report_note': 'Original emitted report copied literally; donor branch metadata is input provenance only.',
        'input_branch_custody': branch_note, 'banked_input_sources': banked_inputs,
        'original_tree': original_tree, 'copies': copies, 'directories': directories,
        'archive_manifest_self_note': 'Manifest SHA256 is stored in archive-manifest.sha256 and printed; generated metadata is separate from originals.',
        'gameplay_reevaluated': False, 'global_closure_claimed': False,
    }


def apply(plan):
    source = Path(plan['original_directory'])
    target = Path(plan['archive_directory'])
    if inventory(source) != plan['original_tree']:
        raise ValueError('closed original run changed after inspection; nothing copied')
    # A failure after creation intentionally leaves evidence for investigation.
    # There is no rollback/deletion and subsequent calls refuse the existing archive.
    target.mkdir(parents=True, exist_ok=False)
    for key in sorted(plan['directories'], key=lambda x: (len(Path(x).parts), x)):
        if key != '.': (target / key).mkdir(exist_ok=True)
    for key, row in sorted(plan['copies'].items()):
        for origin in row['origins']:
            if info(Path(origin['path'])) != row['expected']:
                raise ValueError('original alias changed before copy; partial archive retained')
        data = Path(row['origins'][0]['path']).read_bytes()
        if len(data) != row['expected']['bytes'] or digest(data) != row['expected']['sha256']:
            raise ValueError('original changed during copy; partial archive retained')
        destination = target / key
        with destination.open('xb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        destination.chmod(row['expected']['mode'])
        if info(destination) != row['expected']:
            raise ValueError('portable copy verification failed; partial archive retained')
    if inventory(source) != plan['original_tree']:
        raise ValueError('closed source subtree changed during archive; partial copy retained')
    for row in plan['copies'].values():
        for origin in row['origins']:
            if info(Path(origin['path'])) != row['expected']:
                raise ValueError('original companion changed during archive; partial copy retained')
    copied = inventory(target)
    if copied['files'] != {key: row['expected'] for key, row in plan['copies'].items()}:
        raise ValueError('portable file membership differs; partial copy retained')
    manifest = json_bytes(plan)
    for name, data in [(MANIFEST, manifest), (MANIFEST_SHA, (digest(manifest) + '  ' + MANIFEST + '\n').encode())]:
        with (target / name).open('xb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        (target / name).chmod(0o644)
    # Restore original directory modes only after creating all descendants.
    for key, mode in sorted(plan['directories'].items(), key=lambda x: len(Path(x[0]).parts), reverse=True):
        (target if key == '.' else target / key).chmod(mode)
    final_tree = inventory(target)
    if final_tree['directories'] != plan['directories'] or any(final_tree['files'].get(key) != row['expected'] for key, row in plan['copies'].items()):
        raise ValueError('final portable original bytes/modes differ; archive retained')
    if (target / MANIFEST).read_bytes() != manifest or (target / MANIFEST_SHA).read_text() != digest(manifest) + '  ' + MANIFEST + '\n':
        raise ValueError('new manifest verification failed; archive retained')
    return digest(manifest)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', required=True, type=Path, help='Assigned Act1 checkout')
    parser.add_argument('--run', default='old-east01', choices=['old-east01'], help='Only this closed consumer run is in scope')
    parser.add_argument('--apply', action='store_true', help='Create a new portable copy; otherwise no writes')
    args = parser.parse_args()
    root = args.root.resolve(strict=True)
    plan = inspect(root, args.run)
    manifest_sha = apply(plan) if args.apply else digest(json_bytes(plan))
    print(json.dumps({'action': 'copied_exact_new_archive' if args.apply else 'read_only_plan_no_writes',
                      'run': plan['run'], 'original_directory': plan['original_directory'],
                      'archive_directory': plan['archive_directory'], 'recorded_result': plan['recorded_result'],
                      'recorded_exit_code': plan['recorded_exit_code'], 'file_count': len(plan['copies']),
                      'original_run_file_count': len(plan['original_tree']['files']),
                      'bytes': sum(row['expected']['bytes'] for row in plan['copies'].values()),
                      'manifest_sha256': manifest_sha, 'scope': SCOPE}, indent=2))
    return 0  # Archival success is not a gameplay pass and does not rewrite result.


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print('Archival inspection/copy refused: ' + str(exc), file=sys.stderr)
        raise SystemExit(1)
