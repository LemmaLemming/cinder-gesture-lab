#!/usr/bin/env python3
"""Archive ONE explicitly named CLOSED O1 run; no engine, Git or deletion.
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
SCOPE = ('Exact copies of one explicitly selected CLOSED O1 run and its literal native report/branch companions. '
         'Original failed/incomplete/passed result and source attribution are preserved, not reevaluated. '
         'No engine, Git, deletion, current-runtime comparison, missing-original reconstruction, visual review or global closure claim.')


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

    companions = []
    branches = native.get('branches', {})
    if not isinstance(branches, dict):
        raise ValueError('literal native branches has invalid type')
    for label, row in branches.items():
        single_name(label)
        if not isinstance(row, dict) or row.get('label') != label or not isinstance(row.get('all_original_disk_files'), dict):
            raise ValueError('invalid literal branch row: ' + label)
        branch_root = native.get('branch_root')
        if not isinstance(branch_root, str) or not branch_root.startswith('res://.cinder/'):
            raise ValueError('literal native branch_root required for original companions')
        branch_base = root / relative(branch_root[6:])
        base = branch_base / label
        no_symlinks(base, root / '.cinder')
        if not base.is_relative_to(run):
            for original_dir, target_dir in ((branch_base, 'native-branches'), (base, 'native-branches/' + label)):
                if original_dir.exists():
                    original_mode = original_dir.lstat().st_mode
                    if not stat.S_ISDIR(original_mode):
                        raise ValueError('ordinary original companion directory required')
                    mode = stat.S_IMODE(original_mode)
                    if target_dir in original_tree['directories'] and original_tree['directories'][target_dir] != mode:
                        raise ValueError('original companion directory modes collide: ' + target_dir)
                    directories[target_dir] = mode
        files = row['all_original_disk_files']
        if row.get('complete') is True and ('campaign.json' not in files or row.get('raw_store') != files['campaign.json']):
            raise ValueError('completed branch lacks its literal complete raw Store: ' + label)
        for member, recorded in files.items():
            single_name(member)
            if member == 'branch.json' or not isinstance(recorded, dict):
                raise ValueError('invalid/reserved original branch companion: ' + member)
            path = original_path(root, recorded.get('path'))
            if path != base / member:
                raise ValueError('branch companion path differs from literal branch_root/label/name')
            details = info(path)
            if type(recorded.get('bytes')) is not int or details['bytes'] != recorded['bytes'] or details['sha256'] != recorded.get('sha256'):
                raise ValueError('recorded original companion hash/size differs: ' + str(path))
            # Hex is verification only: it is NEVER used to reconstruct a file.
            if not isinstance(recorded.get('hex'), str) or path.read_bytes().hex() != recorded['hex']:
                raise ValueError('recorded original companion hex differs: ' + str(path))
            target = path.relative_to(run).as_posix() if path.is_relative_to(run) else 'native-branches/' + label + '/' + member
            add(path, target, 'native.json#/branches/' + label + '/all_original_disk_files/' + member)
            companions.append({'branch': label, 'member': member, 'original_path': str(path), 'archive_path': target})
        branch_manifest = base / 'branch.json'
        if row.get('complete') is True and not branch_manifest.is_file():
            raise ValueError('completed branch original manifest missing; never rebuild it')
        if branch_manifest.exists():
            no_symlinks(branch_manifest, root / '.cinder')
            if row.get('complete') is True and read_object(branch_manifest) != row:
                raise ValueError('completed original branch manifest differs from literal native row')
            target = branch_manifest.relative_to(run).as_posix() if branch_manifest.is_relative_to(run) else 'native-branches/' + label + '/branch.json'
            add(branch_manifest, target, 'literal original branch manifest; incomplete rows are not repaired')
    for key in copies:
        if key in directories:
            raise ValueError('final archive file/directory collision: ' + key)
    return {
        'api_revision': 'act1-o1-single-run-archive-1', 'scope': SCOPE,
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
        'native_observed_fields': {key: native.get(key) for key in ('case', 'checks', 'failures', 'complete', 'scope_complete', 'success', 'first_failure')},
        'native_report_note': 'No report synthesized when no original was produced; existing malformed bytes remain literal.',
        'original_tree': original_tree, 'copies': copies, 'directories': directories, 'companions': companions,
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
    parser.add_argument('--run', required=True, help='One basename directly under .cinder/o1-difficulty')
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
