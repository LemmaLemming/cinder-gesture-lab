#!/usr/bin/env python3
"""Bounded read-only Git adoption capture/verification; never merges or ACKs."""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import os
import re
import stat
import subprocess

ROOT = Path('/Users/howardchen/.codex/worktrees/campaign-act1/video game idea')
CANONICAL = Path('/Users/howardchen/Documents/ChatGPT/video game idea')
BASE = '55c9994c7dd1da2ed69e6b0ce5a286b75fd5866d'
PUBLICATION = 'de750e7eec4a70114637834ffe02a25952e40c1e'
BRANCH = 'codex/campaign-act1'
WORKER = '01a11adf-2ec8-7702-96c6-0fa1e240c332'
API = 'campaign-shared-60'
OWNED = ['scenes/acts/act1/', 'scripts/acts/act1/', 'assets/acts/act1/', 'data/campaign/act1/', 'tests/acts/act1/', 'docs/acts/act1/']
UID_MANIFEST = ROOT / '.cinder/a1-o2-terminal-completion01-source/manifest.json'
UID_MANIFEST_SHA = '69be83e9c3c9169879c8c22ce15a1174d8cb06988fd02cbcbfb46eb036fbe391'
O2 = ['scripts/acts/act1/spore_bloom.gd', 'scripts/acts/act1/spore_bloom_layout.gd', 'scripts/acts/act1/spore_bloom_codec.gd', 'scenes/acts/act1/a1_o2.tscn', 'tests/acts/act1/a1_o2_campaign.gd', 'tests/acts/act1/a1_o2_terminal.gd', 'tests/acts/act1/a1_o2_saved_portrait.gd', 'tests/acts/act1/a1_o2_mechanics.gd', 'tests/acts/act1/a1_o2_groups.gd', 'tests/acts/act1/fixtures/a1_o2_saved_portrait_sources.json']
O2 += [p + '.uid' for p in O2 if p.endswith('.gd')]
O1 = ['scripts/acts/act1/salvage_circuit.gd', 'scripts/acts/act1/salvage_circuit_codec.gd', 'scripts/acts/act1/salvage_circuit_layout.gd', 'scripts/acts/act1/salvage_circuit_part.gd', 'scripts/acts/act1/salvage_circuit_scenery.gd', 'scenes/acts/act1/a1_o1.tscn', 'tests/acts/act1/a1_o1_campaign.gd', 'tests/acts/act1/a1_o1_saved_portrait.gd', 'tests/acts/act1/a1_o1_saved_portrait.gd.uid', 'tests/acts/act1/fixtures/a1_o1_saved_portrait_sources.json', 'docs/acts/act1/evidence/O1-final-focused/index.json', 'docs/acts/act1/evidence/O1-portrait-focused/index.json', 'docs/acts/act1/O1_SUBMISSION_MANIFEST.json']
NAMED = O2 + O1 + ['scripts/campaign/exact_json.gd']
SETTINGS = ['project.godot', '.cinder/local.json', 'override.cfg']
ACTIVE_NEW_UIDS = {'scripts/acts/act3/pillars_before_time.gd.uid', 'scripts/acts/act3/temporal_marker_prop.gd.uid', 'tests/act3_o1_registration_smoke.gd.uid', 'tests/acts/act3/pillars_before_time_focused.gd.uid', 'tests/acts/act3/pillars_before_time_optional_shell.gd.uid', 'tests/acts/act3/pillars_before_time_portrait.gd.uid'}
SHARED = ['data/campaign/registry.json', 'scripts/dev/dev.py', 'scripts/settings/game_settings.gd']
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS='0')

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, env=ENV)

def textgit(*args):
    return git(*args).decode().strip()

def ancestor(older, newer):
    subprocess.run(['git', 'merge-base', '--is-ancestor', older, newer], cwd=ROOT, env=ENV, check=True)

def digest(data):
    return hashlib.sha256(data).hexdigest()

def blob_oid(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()

def physical(rel):
    p = ROOT / rel
    if not p.exists():
        assert not p.is_symlink(), rel
        return None
    info = p.lstat()
    assert stat.S_ISREG(info.st_mode) and not p.is_symlink(), rel
    data = p.read_bytes()
    return {'sha256': digest(data), 'git_blob': blob_oid(data), 'bytes': len(data), 'mode': stat.S_IMODE(info.st_mode)}

def trees(revision):
    return {p: textgit('rev-parse', revision + ':' + p.rstrip('/')) for p in OWNED}

def entries(revision, paths):
    result = {}
    for entry in git('ls-tree', '-r', '-z', '--full-tree', revision, '--', *paths).split(b'\0'):
        if not entry:
            continue
        metadata, path = entry.split(b'\t', 1)
        mode, kind, oid = metadata.decode().split()
        assert kind == 'blob' and mode in ['100644', '100755']
        result[path.decode()] = {'mode': mode, 'oid': oid}
    return result

def diff_rows(old, new, *paths):
    args = ['diff', '--raw', '--no-abbrev', '--no-renames', '-z', old, new]
    if paths:
        args += ['--', *paths]
    fields = git(*args).split(b'\0')
    result = []
    for index in range(0, len(fields) - 1, 2):
        old_mode, mode, old_oid, oid, status = fields[index].decode().split()
        path = fields[index + 1].decode()
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        result.append({'path': path, 'status': status, 'old_mode': old_mode[1:], 'mode': mode, 'old_oid': old_oid, 'oid': oid})
    return result

def publication_envelope():
    assert textgit('rev-parse', PUBLICATION + '^{commit}') == PUBLICATION
    ancestor(BASE, PUBLICATION)
    rows = diff_rows(BASE, PUBLICATION)
    assert len(rows) == 418
    blobs = {}
    total = 0
    for row in rows:
        assert row['status'] in ['A', 'M'] and row['mode'] in ['100644', '100755'], row
        assert not any(row['path'].startswith(p) for p in OWNED), row['path']
        data = git('cat-file', 'blob', row['oid'])
        assert blob_oid(data) == row['oid']
        row['sha256'] = digest(data)
        row['bytes'] = len(data)
        total += len(data)
        blobs[row['path']] = data
    assert total == 10180676, total
    assert trees(BASE) == trees(PUBLICATION)
    runtime_paths = [p for p in blobs if p.startswith('scripts/') and not p.startswith('scripts/acts/act3/')]
    assert set(runtime_paths) == {'scripts/dev/dev.py', 'scripts/settings/game_settings.gd'}
    old_registry = json.loads(git('show', BASE + ':data/campaign/registry.json'))
    new_registry = json.loads(blobs['data/campaign/registry.json'])
    before = next(r for r in old_registry['levels'] if r['id'] == 'A3-O1')
    after = next(r for r in new_registry['levels'] if r['id'] == 'A3-O1')
    changed_keys = {k for k in before.keys() | after.keys() if before.get(k) != after.get(k)}
    assert changed_keys == {'scene_path', 'readiness', 'accepted_commit', 'api_revision'}
    assert after['scene_path'] == 'res://scenes/acts/act3/a3_o1_pillars_before_time.tscn' and after['readiness'] == 'accepted'
    assert after['accepted_commit'] == '3ece87b82f5b91023bdae94da013933ab9c4fd3b' and after['api_revision'] == 'campaign-level-1'
    old_registry['levels'] = [r for r in old_registry['levels'] if r['id'] != 'A3-O1']
    new_registry['levels'] = [r for r in new_registry['levels'] if r['id'] != 'A3-O1']
    assert old_registry == new_registry
    alias = b'    "act3_o1_registration": "tests/act3_o1_registration_smoke.gd",\n'
    assert blobs['scripts/dev/dev.py'].count(alias) == 1
    assert blobs['scripts/dev/dev.py'].replace(alias, b'', 1) == git('show', BASE + ':scripts/dev/dev.py')
    code = lambda data: b'\n'.join(line for line in data.splitlines() if not line.lstrip().startswith(b'#'))
    assert code(blobs['scripts/settings/game_settings.gd']) == code(git('show', BASE + ':scripts/settings/game_settings.gd'))
    exact = textgit('rev-parse', BASE + ':scripts/campaign/exact_json.gd')
    assert exact == textgit('rev-parse', PUBLICATION + ':scripts/campaign/exact_json.gd')
    return rows, blobs, {'registry_changed_level_only': 'A3-O1', 'registry_row': after, 'dev_alias_only': 'act3_o1_registration', 'game_settings_executable_text_unchanged': True, 'exact_json_git_blob_unchanged': exact, 'incoming_blob_bytes': total}

def known_uids(manifest_path, expected_sha):
    data = manifest_path.read_bytes()
    assert digest(data) == expected_sha
    manifest = json.loads(data)
    assert manifest['api_revision'] == API
    rows = [row for row in manifest['files'] if row['path'].endswith('.uid')]
    assert len(rows) == 535
    known = {}
    for row in rows:
        rel = Path(row['path'])
        assert not rel.is_absolute() and '..' not in rel.parts
        p = manifest_path.parent / rel
        info, data = p.lstat(), p.read_bytes()
        assert stat.S_ISREG(info.st_mode) and not p.is_symlink()
        assert info.st_size == row['bytes'] and stat.S_IMODE(info.st_mode) == row['mode'] and digest(data) == row['sha256']
        uid = data.decode().strip()
        assert re.fullmatch(r'uid://[a-z0-9]+', uid) and uid not in known, rel
        known[uid] = row['path']
    return known, {'manifest': str(manifest_path), 'manifest_sha256': expected_sha, 'source_revision': manifest['revision'], 'api_revision': manifest['api_revision'], 'known_active_uid_values': len(known), 'method': 'Only the535 named UID members of this retained job bank were read/verified. No current physical UID tree, historical bank or evidence census.'}

def incoming_uids(rows, blobs, known):
    uid_rows = [row for row in rows if row['path'].endswith('.uid')]
    active = [row for row in uid_rows if row['path'] in ACTIVE_NEW_UIDS]
    mirrors = [row for row in uid_rows if row['path'] not in ACTIVE_NEW_UIDS]
    assert len(active) == 6 and len(mirrors) == 6 and {r['path'] for r in active} == ACTIVE_NEW_UIDS
    values = {}
    for row in active:
        assert row['status'] == 'A' and row['path'][:-4] in blobs
        uid = blobs[row['path']].decode().strip()
        assert re.fullmatch(r'uid://[a-z0-9]+', uid) and uid not in known and uid not in values
        values[uid] = row['path']
    for row in mirrors:
        assert row['status'] == 'A' and row['path'].startswith('docs/development/evidence/act3-o1-integration/publication/archive/')
        matches = [p for p in ACTIVE_NEW_UIDS if row['path'].endswith('/' + p)]
        assert len(matches) == 1 and blobs[row['path']] == blobs[matches[0]]
    return {'new_genuine_published_active_uid_values': values, 'inactive_archive_mirror_paths': [r['path'] for r in mirrors], 'existing_known_values_disjoint': True, 'known_before_count': 535, 'expected_active_count_after_exact_addition': 541, 'limitation': '541 is derived from the retained535 known set plus six exact published additions; this is not a new all-files physical uniqueness census.'}

def ownership():
    run = json.loads((CANONICAL / '.cinder/agent-chat/cinder-campaign/run.json').read_text())
    worker = run['workers']['act1']
    assert worker['worker_id'] == WORKER and worker['checkout'] == str(ROOT) and worker['branch'] == BRANCH and worker['owned_paths'] == OWNED
    assert worker['worker_baseline'] == BASE and worker['worker_api_revision'] == API
    assert textgit('branch', '--show-current') == BRANCH
    return {'worker_id': WORKER, 'checkout': str(ROOT), 'branch': BRANCH, 'owned_paths': OWNED, 'canonical_worker_baseline': BASE, 'api_revision': API, 'scope_change': False}

def capture(expected_head, manifest_path, manifest_sha):
    head = textgit('rev-parse', 'HEAD')
    assert head == expected_head and re.fullmatch('[0-9a-f]{40}', head)
    owner = ownership()
    ancestor(BASE, head)
    assert textgit('merge-base', head, PUBLICATION) == BASE
    assert not git('diff', '--name-only', 'HEAD'), 'Commit/review any tracked changes before fresh capture.'
    rows, blobs, envelope = publication_envelope()
    previous = entries(head, [r['path'] for r in rows])
    for row in rows:
        physical_before = physical(row['path'])
        if row['status'] == 'A':
            assert row['path'] not in previous and physical_before is None, row['path']
        else:
            assert previous[row['path']] == {'mode': row['old_mode'], 'oid': row['old_oid']}, row['path']
            assert physical_before is not None and physical_before['git_blob'] == row['old_oid'] and physical_before['mode'] == int(row['old_mode'][-3:], 8), row['path']
    known, custody = known_uids(manifest_path, manifest_sha)
    uids = incoming_uids(rows, blobs, known)
    named = {p: physical(p) for p in NAMED}
    assert all(value is not None for value in named.values())
    assert textgit('rev-parse', head + ':scripts/campaign/exact_json.gd') == envelope['exact_json_git_blob_unchanged']
    return {'status': 'SOURCE_ONLY_PREFLIGHT_NOT_AN_ADOPTION', 'captured_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'publication': PUBLICATION, 'baseline': BASE, 'prior_head': head, 'owner': owner, 'owned_tree_objects': trees(head), 'named_physical_files': named, 'local_settings': {p: physical(p) for p in SETTINGS}, 'incoming_files': rows, 'incoming_count': len(rows), 'publication_envelope': envelope, 'known_uid_custody': custody, 'uid_delta': uids, 'all_terminal_cases_closed': 'Root must independently establish this safe boundary before performing a merge; this preparation does not assert job closure.', 'scope': 'Six exact owned Git tree objects;32 named critical physical files including O2 current3 fixtures plus mechanics/groups; three local settings; all418 incoming publication blobs/modes; six genuine published activeUIDs against535 retained known values. No Git mutation, merge, import, engine, mailbox, actual adoption receipt/ACK, broad physical UID/evidence census, source copy or archive.'}

def verify(plan, all_cases_closed):
    assert all_cases_closed, 'Root must explicitly establish all terminal cases/jobs closed before actual merge verification.'
    assert plan['status'] == 'SOURCE_ONLY_PREFLIGHT_NOT_AN_ADOPTION' and plan['publication'] == PUBLICATION and plan['baseline'] == BASE
    assert ownership() == plan['owner']
    merge = textgit('rev-parse', 'HEAD')
    parents = textgit('show', '-s', '--format=%P', merge).split()
    assert parents == [plan['prior_head'], PUBLICATION]
    ancestor(plan['prior_head'], merge)
    ancestor(PUBLICATION, merge)
    assert trees(merge) == plan['owned_tree_objects']
    assert {p: physical(p) for p in plan['named_physical_files']} == plan['named_physical_files']
    assert {p: physical(p) for p in plan['local_settings']} == plan['local_settings']
    expected = {row['path']: row for row in plan['incoming_files']}
    actual_entries = entries(merge, list(expected))
    for path, row in expected.items():
        assert actual_entries[path] == {'mode': row['mode'], 'oid': row['oid']}
        actual = physical(path)
        assert actual is not None and actual['git_blob'] == row['oid'] and actual['sha256'] == row['sha256'] and actual['bytes'] == row['bytes'] and actual['mode'] == int(row['mode'][-3:], 8), path
    delta = diff_rows(plan['prior_head'], merge, '*.uid')
    expected_uids = {p for p in expected if p.endswith('.uid')}
    assert {row['path'] for row in delta} == expected_uids and all(row['status'] == 'A' for row in delta)
    assert not git('diff', '--name-only', 'HEAD')
    custody = plan['known_uid_custody']
    known, readback = known_uids(Path(custody['manifest']), custody['manifest_sha256'])
    assert readback == custody
    uid_values = plan['uid_delta']['new_genuine_published_active_uid_values']
    assert all((ROOT / path).read_text().strip() == uid and uid not in known for uid, path in uid_values.items())
    return {'status': 'ACTUAL_MERGE_VERIFIED_FOR_ROOT_RECEIPT', 'verified_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'publication': PUBLICATION, 'baseline': BASE, 'prior_head': plan['prior_head'], 'merge_commit': merge, 'parents': parents, 'owner': plan['owner'], 'owned_tree_objects_preserved': plan['owned_tree_objects'], 'named_physical_files_preserved': plan['named_physical_files'], 'local_settings_preserved': plan['local_settings'], 'incoming_files_exact': plan['incoming_files'], 'known_uid_custody': custody, 'uid_delta': plan['uid_delta'], 'all_terminal_cases_closed': 'Explicitly asserted by Root at verification invocation; not inferred by this source checker.', 'scope': 'Actual two-parent merge and bounded preservation verified. This script writes only the requested private/tmp verification JSON. Root may create the actual owned adoption receipt and canonical ACK separately; no mailbox or registration mutation has occurred here. No new engine/import or full physical UID census.'}

def write_output(path, result):
    resolved = path.resolve()
    assert Path('/private/tmp') in resolved.parents, 'Only private/tmp output is supported.'
    with resolved.open('x') as out:
        json.dump(result, out, indent=2)
        out.write('\n')
    print(json.dumps({'output': str(resolved), 'sha256': digest(resolved.read_bytes()), 'bytes': resolved.stat().st_size, 'status': result['status'], 'publication': PUBLICATION}, indent=2))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='operation', required=True)
    pre = commands.add_parser('capture')
    pre.add_argument('--expected-head', required=True)
    pre.add_argument('--uid-bank-manifest', type=Path, default=UID_MANIFEST)
    pre.add_argument('--uid-bank-manifest-sha256', default=UID_MANIFEST_SHA)
    pre.add_argument('--output', type=Path, required=True)
    post = commands.add_parser('verify')
    post.add_argument('--capture', type=Path, required=True)
    post.add_argument('--capture-sha256', required=True)
    post.add_argument('--all-terminal-cases-closed', action='store_true')
    post.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.operation == 'capture':
        result = capture(args.expected_head, args.uid_bank_manifest, args.uid_bank_manifest_sha256)
    else:
        data = args.capture.read_bytes()
        assert digest(data) == args.capture_sha256
        result = verify(json.loads(data), args.all_terminal_cases_closed)
    write_output(args.output, result)

if __name__ == '__main__':
    main()
