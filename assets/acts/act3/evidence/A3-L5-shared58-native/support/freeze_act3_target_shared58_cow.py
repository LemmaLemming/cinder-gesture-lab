from pathlib import Path
import sys, re, json, hashlib, datetime, subprocess, os, stat
root = Path.cwd()
dest = Path(sys.argv[1])
starts = sys.argv[2:]
previous = Path('.cinder/crystalman-c50-public-shared57-paused-portrait-retry')
manifest_path = previous / 'source-freeze.json'
manifest_bytes = manifest_path.read_bytes()
prior = json.loads(manifest_bytes)
assert not dest.exists(), dest
assert prior['roots'] == starts
assert prior['api_revision'] == 'campaign-shared-57'
assert len(prior['sources']) == 575
# This reviewed fixture derivative adds only JSON data I/O, no new runtime
# resource or custom-class dependency. A new existing literal res path refuses
# this reused closure and requires a separately reviewed scope.
collected = {}
changed = []
for name, old_sha in prior['sources'].items():
    current = Path(name)
    assert current.is_file() and not current.is_symlink(), name
    blob = current.read_bytes()
    sha = hashlib.sha256(blob).hexdigest()
    if sha != old_sha:
        changed.append(name)
        if current.suffix in ['.gd', '.tscn', '.tres', '.godot', '.json', '.import']:
            for ref in re.findall(r'res://([^\s\"\'\)]+)', blob.decode('utf-8')):
                assert not Path(ref).is_file() or ref in prior['sources'], ref
    collected[name] = sha
assert set(changed) <= {'tests/acts/act3/crystalman_regular_priority_smoke.gd', 'scripts/campaign/shell.gd'}, changed
assert collected['scripts/campaign/shell.gd'] == 'f8df3b798544b79d66985f5e468f13ade5485bccc6050b54c9d9d242b3211a0f'
subprocess.run(['git','merge-base','--is-ancestor','6d5b8b45e0147e50fb75e8e27a1e6facb72dac3e','HEAD'],check=True)
sources = {}
clone_origins = {}
for name, sha in collected.items():
    current = Path(name)
    st = current.stat()
    origin = previous / 'sources' / name if sha == prior['sources'][name] else current
    assert hashlib.sha256(origin.read_bytes()).hexdigest() == sha, str(origin)
    target = dest / 'sources' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['/bin/cp', '-c', '-p', str(origin), str(target)], check=True)
    os.chmod(target, stat.S_IMODE(st.st_mode))
    os.utime(target, ns=(st.st_atime_ns, st.st_mtime_ns))
    assert hashlib.sha256(target.read_bytes()).hexdigest() == sha, str(target)
    assert target.stat().st_ino != origin.stat().st_ino and target.stat().st_nlink == 1
    assert hashlib.sha256(current.read_bytes()).hexdigest() == sha, name
    sources[name] = sha
    clone_origins[name] = str(origin)
assert manifest_path.read_bytes() == manifest_bytes
manifest = {
    'baseline': '6d5b8b45e0147e50fb75e8e27a1e6facb72dac3e', 'api_revision': 'campaign-shared-58',
    'owned_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
    'created_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'scope': 'Prior reviewed575-path closure reused for owned saved-warning fixture and exact published Shared58 Shell scheduling fix; current original bytes verified; independent APFS COW new copies only, no existing file replacement/hardlink; no native credit.',
    'prior_manifest': str(manifest_path),
    'prior_manifest_sha256': hashlib.sha256(manifest_bytes).hexdigest(),
    'reviewed_changed_paths': changed, 'roots': starts, 'sources': sources,
    'clone_origins': clone_origins}
(dest / 'source-freeze.json').write_text(json.dumps(manifest, indent=2) + '\n')
print('Frozen', len(sources), 'source inputs with independent COW copies at', dest, flush=True)
