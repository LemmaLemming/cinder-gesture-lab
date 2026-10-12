import datetime
import hashlib
import json
import pathlib
import shutil
import stat
import subprocess

ROOT = pathlib.Path.cwd()
PUB = 'afa6fbfdd14f8ffb917829fa7ca1a5d44ae40b79'
BASE = 'bd3c4458cbd1821b79c2bcda6e33f8dbaa0d5e4d'
OWN = ('scripts/acts/act2/', 'scenes/acts/act2/', 'assets/acts/act2/',
       'data/campaign/act2/', 'tests/acts/act2/', 'docs/acts/act2/')
OUT = ROOT / 'docs/acts/act2/evidence/shared42-adoption'
assert not OUT.exists()
OUT.mkdir()
(OUT / '.gdignore').write_text('')

def sha(data):
    return hashlib.sha256(data).hexdigest()

def git(*args):
    return subprocess.check_output(['git', *args])

def record(path):
    mode = stat.S_IMODE(path.stat().st_mode)
    return {'sha256': sha(path.read_bytes()), 'mode': oct(mode), 'executable_bits': mode & 0o111}

def indexed():
    result = {}
    for row in git('ls-files', '--stage', '-z').split(b'\0'):
        if row:
            meta, name = row.split(b'\t', 1)
            mode, blob, stage = meta.decode().split()
            result[name.decode()] = {'git_mode': mode, 'blob': blob, 'stage': stage}
    return result

def uid_rows():
    return {p.relative_to(ROOT).as_posix(): record(p) for folder in ('scripts', 'tests', 'assets')
            for p in (ROOT / folder).rglob('*.uid') if p.name.endswith(('.gd.uid', '.gdshader.uid'))}

def tree(rev):
    result = {}
    for row in git('ls-tree', '-r', '-z', rev).split(b'\0'):
        if row:
            meta, name = row.split(b'\t', 1)
            mode, kind, blob = meta.decode().split()
            assert kind == 'blob', name
            result[name.decode()] = {'git_mode': mode, 'blob': blob}
    return result

subprocess.run(['git', 'merge-base', '--is-ancestor', BASE, PUB], check=True)
tracked = {p: r for p, r in indexed().items() if p.startswith(OWN)}
physical = {p.relative_to(ROOT).as_posix(): record(p) for prefix in OWN
            for p in (ROOT / prefix).rglob('*') if p.is_file() and not p.is_relative_to(OUT)}
uids = uid_rows()
assert len(uids) == 329, len(uids)
settings = {p: record(ROOT / p) for p in ('project.godot', '.cinder/local.json', '.vscode/settings.json')}
pub_tree = tree(PUB)
changed = [p.decode() for p in git('diff', '--name-only', '-z', BASE, PUB).split(b'\0') if p]
assert len(changed) == 15172, len(changed)
assert not any(p.startswith(OWN) for p in changed)
assert all(p in pub_tree for p in changed), 'unexpected deletion'
incoming = {p: dict(pub_tree[p]) for p in changed}
blobs = list(dict.fromkeys(r['blob'] for r in incoming.values()))
cat = subprocess.Popen(['git', 'cat-file', '--batch'], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
hashes = {}
for blob in blobs:
    cat.stdin.write((blob + '\n').encode())
    cat.stdin.flush()
    header = cat.stdout.readline().decode().split()
    assert header[0] == blob and header[1] == 'blob'
    data = cat.stdout.read(int(header[2]))
    assert cat.stdout.read(1) == b'\n'
    hashes[blob] = sha(data)
cat.stdin.close()
assert cat.wait() == 0
for row in incoming.values():
    row['sha256'] = hashes[row['blob']]

old_head = git('rev-parse', 'HEAD').decode().strip()
assert old_head == '817adf644342e35894fe4d61161fb7ccc85a519b'
assert not git('diff', '--name-only').strip() and not git('diff', '--cached', '--name-only').strip()
before = {'at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'publication': PUB,
          'preceding_actual_baseline': BASE, 'before_head': old_head,
          'before_status': git('status', '--short').decode(), 'owned_tracked': tracked,
          'owned_physical': physical, 'active_uid_rows': uids, 'settings': settings,
          'incoming': incoming,
          'source_hold': 'All owned Godot jobs CLOSED: loading/Retry5323 clean89/0. TMP subagents do not alter this checkout. Current production component sealed817adf6.'}
(OUT / 'before.json').write_text(json.dumps(before, indent=2, sort_keys=True) + '\n')

# These exact untracked shared identities are already the incoming canonical blobs.
# Preserve them outside the checkout during Git merge, then verify the installed copies.
held = pathlib.Path('/private/tmp/cinder-a2-shared42-original-uids')
assert not held.exists()
held.mkdir()
held_rows = {}
for name in ('tests/authored_source_guard_reference_smoke.gd.uid', 'tests/lane_parent_presentation_smoke.gd.uid'):
    path = ROOT / name
    assert name not in indexed() and record(path)['sha256'] == incoming[name]['sha256']
    held_rows[name] = record(path)
    dest = held / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(path, dest)
with (OUT / 'merge.log').open('x') as log:
    merged = subprocess.run(['git', 'merge', '--no-ff', PUB, '-m', 'Merge compatible Shared42 into Act 2 preserving content'], stdout=log, stderr=subprocess.STDOUT)
assert merged.returncode == 0, (OUT / 'merge.log').read_text()

rows = indexed()
findings = []
for name, row in tracked.items():
    if rows.get(name) != row:
        findings.append('tracked:' + name)
for name, row in physical.items():
    if not (ROOT / name).is_file() or record(ROOT / name) != row:
        findings.append('physical:' + name)
after_uids = uid_rows()
for name, row in uids.items():
    if after_uids.get(name) != row:
        findings.append('uid:' + name)
new_uids = {name: row for name, row in after_uids.items() if name not in uids}
for name, row in new_uids.items():
    if name not in incoming or row['sha256'] != incoming[name]['sha256']:
        findings.append('unexpected-new-uid:' + name)
for name, row in settings.items():
    if record(ROOT / name) != row:
        findings.append('setting:' + name)
for name, row in incoming.items():
    index_row = rows.get(name)
    path = ROOT / name
    if (not path.is_file() or index_row is None or record(path)['sha256'] != row['sha256']
            or index_row['git_mode'] != row['git_mode'] or index_row['blob'] != row['blob']
            or bool(stat.S_IMODE(path.stat().st_mode) & 0o111) != (row['git_mode'] == '100755')):
        findings.append('incoming:' + name)
for name, row in held_rows.items():
    if record(ROOT / name) != row or record(held / name) != row:
        findings.append('shared-original-uid:' + name)
assert not findings, findings
head = git('rev-parse', 'HEAD').decode().strip()
parents = git('show', '-s', '--format=%P', head).decode().split()
assert parents == [old_head, PUB]
receipt = {'at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
           'status': 'Exact preserving compatible Shared42 adoption', 'publication': PUB,
           'preceding_actual_baseline': BASE, 'merge': head, 'parents': parents,
           'before_sha256': sha((OUT / 'before.json').read_bytes()),
           'merge_log_sha256': sha((OUT / 'merge.log').read_bytes()),
           'owned_tracked_preserved': len(tracked), 'owned_physical_preserved': len(physical),
           'active_prior_script_shader_uid_bytes_modes_preserved': len(uids),
           'new_incoming_exact_uid_rows': new_uids, 'active_uid_count_after': len(after_uids),
           'shared_generated_identity_custody': held_rows, 'held_original_copy': str(held),
           'local_settings_preserved': len(settings), 'incoming_exact_git_physical_modes': len(incoming),
           'findings': findings,
           'scope': 'A3-L3 accepted content/registry and exact shared metadata plus original evidence. No Act2 owned delta or common mechanical kernel change. Historical41 passes retain original scopes; adoption provides no native/import/portrait execution credit.'}
(OUT / 'adoption.json').write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n')
print(json.dumps({k: v for k, v in receipt.items() if k not in ('new_incoming_exact_uid_rows', 'shared_generated_identity_custody')}, sort_keys=True))
