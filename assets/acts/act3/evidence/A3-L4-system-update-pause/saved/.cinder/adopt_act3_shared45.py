import datetime
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess

ROOT = Path(__file__).resolve().parent.parent
CANONICAL = Path('/Users/howardchen/Documents/ChatGPT/video game idea')
PUBLICATION = 'ca82dffa1f0cfece41df46580b1d297de6bdf8bf'
PREVIOUS = 'd22cb47b2346a54e81ca6c5ed77f36efd1b4b667'
PREFIXES = ['scenes/acts/act3/', 'scripts/acts/act3/', 'assets/acts/act3/',
            'tests/acts/act3/', 'docs/acts/act3/', 'data/campaign/act3/']
BEFORE = ROOT / '.cinder/false-paradise-shared45-adoption-before.json'
AFTER = ROOT / '.cinder/false-paradise-shared45-adoption.json'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()

def physical(path):
    p = Path(path)
    if not p.is_absolute():
        p = ROOT / p
    data = os.readlink(p).encode() if p.is_symlink() else p.read_bytes()
    return {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data),
            'mode': stat.S_IMODE(p.lstat().st_mode),
            'native_blob_oid': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()}

def index_rows():
    rows = {}
    for entry in git('ls-files', '--stage', '-z', '--', *PREFIXES).split(b'\0'):
        if not entry:
            continue
        fields, path = entry.split(b'\t', 1)
        mode, oid, stage = fields.decode().split()
        assert stage == '0', (path, stage)
        rows[path.decode()] = {'mode': mode, 'oid': oid}
    return rows

def tree_rows(rev):
    rows = {}
    for entry in git('ls-tree', '-r', '-z', rev).split(b'\0'):
        if not entry:
            continue
        fields, path = entry.split(b'\t', 1)
        mode, kind, oid = fields.decode().split()
        rows[path.decode()] = {'mode': mode, 'type': kind, 'oid': oid}
    return rows

def owned_physical():
    return {str(p.relative_to(ROOT)): physical(p) for prefix in PREFIXES
            for p in sorted((ROOT / prefix).rglob('*')) if p.is_file() or p.is_symlink()}

def uids():
    rows = {}
    for prefix in ['scripts', 'tests', 'assets']:
        for p in sorted((ROOT / prefix).rglob('*.uid')):
            if 'evidence' in p.relative_to(ROOT).parts:
                continue
            value = p.read_text().strip()
            assert value.startswith('uid://'), str(p)
            rows[str(p.relative_to(ROOT))] = value
    return rows

def settings():
    return {p: physical(p) for p in ['.cinder/local.json', '.cinder/cinder.code-workspace']}

def ledgers():
    paths = ['data/design/equipment_claims.json', 'data/design/ability_usage.json']
    return {p: physical(p) for p in paths + [str(CANONICAL / p) for p in paths]}

def save(p, data):
    tmp = p.with_suffix(p.suffix + '.tmp')
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n')
    tmp.replace(p)

def prepare():
    assert not BEFORE.exists(), 'Do not overwrite an original custody receipt'
    assert git('branch', '--show-current').decode().strip() == 'codex/campaign-act3'
    delta = git('diff', '--name-only', '-z', PREVIOUS, PUBLICATION).split(b'\0')
    delta = [p.decode() for p in delta if p]
    assert not any(p.startswith(tuple(PREFIXES)) for p in delta), 'incoming ownership overlap'
    rows, files = index_rows(), owned_physical()
    for path, row in rows.items():
        assert files[path]['native_blob_oid'] == row['oid'], ('dirty owned tracked file', path)
    data = {'created_at': now(), 'old_head': git('rev-parse', 'HEAD').decode().strip(),
            'publication': PUBLICATION, 'previous_publication': PREVIOUS, 'prefixes': PREFIXES,
            'owned_tracked': rows, 'owned_physical': files, 'settings': settings(),
            'ledgers': ledgers(), 'active_uids': uids(), 'incoming_delta_paths': delta,
            'engine_jobs_for_adoption': 0, 'scope': 'All own frozen jobs were closed before custody/adoption.'}
    save(BEFORE, data)
    print(json.dumps({'receipt': str(BEFORE), 'head': data['old_head'],
                      'owned_tracked': len(rows), 'owned_physical': len(files),
                      'uid_count': len(data['active_uids']), 'incoming': len(delta)}))

def verify():
    assert not AFTER.exists(), 'Do not overwrite an original adoption receipt'
    before = json.loads(BEFORE.read_text())
    head = git('rev-parse', 'HEAD').decode().strip()
    parents = git('rev-list', '--parents', '-n', '1', head).decode().strip().split()[1:]
    assert parents == [before['old_head'], PUBLICATION], parents
    assert index_rows() == before['owned_tracked'], 'Owned Git rows changed'
    assert owned_physical() == before['owned_physical'], 'Owned physical bytes/modes changed'
    assert settings() == before['settings'], 'Worker settings changed'
    assert ledgers() == before['ledgers'], 'Worker/canonical ledgers changed'
    current_uids = uids()
    assert all(current_uids.get(p) == v for p, v in before['active_uids'].items()), 'Prior UID changed'
    by_value = {}
    for path, value in current_uids.items():
        by_value.setdefault(value, []).append(path)
    collisions = {v: ps for v, ps in by_value.items() if len(ps) > 1}
    assert not collisions, collisions
    publication_rows, merged_rows = tree_rows(PUBLICATION), tree_rows(head)
    incoming = []
    for path in before['incoming_delta_paths']:
        pub = publication_rows.get(path)
        if pub is None:
            assert path not in merged_rows and not (ROOT / path).exists(), path
            incoming.append({'path': path, 'deleted': True})
            continue
        assert merged_rows[path] == pub, ('incoming Git mismatch', path)
        file = physical(path)
        assert file['native_blob_oid'] == pub['oid'], ('incoming physical mismatch', path)
        expected_mode = 0o755 if pub['mode'] == '100755' else 0o644
        assert file['mode'] == expected_mode, ('incoming mode mismatch', path)
        incoming.append({'path': path, **pub, **file})
    data = {'completed_at': now(), 'preserving_merge': head, 'parents': parents,
            'publication': PUBLICATION, 'previous_publication': PREVIOUS,
            'api_revision': 'campaign-shared-45',
            'before_receipt_sha256': hashlib.sha256(BEFORE.read_bytes()).hexdigest(),
            'owned_tracked_count': len(before['owned_tracked']),
            'owned_physical_count': len(before['owned_physical']),
            'owned_index_and_physical_exact': True, 'settings_exact': before['settings'],
            'ledgers_exact': before['ledgers'], 'incoming_delta_count': len(incoming),
            'incoming_index_blob_bytes_modes_exact': True, 'incoming_rows': incoming,
            'uid_scope': 'All physical source sidecars under scripts/tests/assets excluding evidence archives',
            'prior_uid_count': len(before['active_uids']), 'prior_uids_exact': True,
            'current_uid_count': len(current_uids),
            'new_uids': {p: v for p, v in current_uids.items() if p not in before['active_uids']},
            'uid_collisions': len(collisions), 'engine_jobs_for_adoption': 0,
            'limitations': ['Custody-only: no engine/import/native or retroactive Shared45 test credit.',
                            'A1-L2 new arrangement reader adopted; previous A3 native results retain their original Shared44 source attribution.',
                            'Two new full-level owned source candidates and five prior preview files remain exact untracked bytes.']}
    save(AFTER, data)
    print(json.dumps({k: data[k] for k in ['preserving_merge', 'parents', 'owned_tracked_count',
          'owned_physical_count', 'incoming_delta_count', 'prior_uid_count', 'current_uid_count',
          'new_uids', 'uid_collisions']}))

if __name__ == '__main__':
    import sys
    {'prepare': prepare, 'verify': verify}[sys.argv[1]]()
