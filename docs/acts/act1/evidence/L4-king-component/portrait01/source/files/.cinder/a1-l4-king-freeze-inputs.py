from pathlib import Path
import sys, json, re, hashlib, shutil, subprocess, datetime

root = Path(__file__).resolve().parent.parent
destination = root / sys.argv[1]
if destination.exists():
    raise SystemExit('Original input archive already exists; never overwrite')
destination.mkdir(parents=True)
(destination / '.gdignore').write_text('')
prior = json.loads((root / 'docs/development/evidence/act1-l3-focused-transport/focused-transport/source/manifest.json').read_text())
seed_paths = {row['path'] for row in prior['files'] if (root / row['path']).is_file()}
extra = [
    '.cinder/local.json', 'project.godot', 'scenes/main.tscn',
    'scripts/dev/dev.py', '.cinder/a1-l4-king-freeze-inputs.py',
    '.cinder/a1-l4-king-run.py',
    'scripts/acts/act1/selenite_king.gd',
    'scripts/acts/act1/selenite_king_art.gd',
    'scripts/acts/act1/selenite_king_greybox.gd',
    'scenes/acts/act1/a1_l4_king_greybox.tscn',
    'tests/acts/act1/a1_l4_king_greybox.gd',
    'assets/acts/act1/court/king_manifest.json',
    'data/campaign/act1/levels/A1-L4.md',
    'data/campaign/act1/levels/A1-L4-formation-design-query-2026-10-12.json',
]
for path in extra:
    if not (root / path).is_file():
        raise SystemExit('Required explicit King input missing: ' + path)
seed_paths.update(extra)
for path in ['.godot/global_script_class_cache.cfg', '.godot/uid_cache.bin']:
    if (root / path).is_file(): seed_paths.add(path)
pending = list(sorted(seed_paths)); seen = set(); missing = set()
while pending:
    path = pending.pop()
    if path in seen: continue
    source = root / path
    if not source.is_file():
        missing.add(path); continue
    seen.add(path)
    for sidecar in [path + '.uid', path + '.import']:
        if (root / sidecar).is_file() and sidecar not in seen: pending.append(sidecar)
    if source.suffix in ['.gd', '.tscn', '.tres', '.godot', '.json', '.import', '.cfg']:
        try: content = source.read_text()
        except UnicodeError: continue
        for reference in re.findall(r'res://([^"\s\)]+)', content):
            reference = reference.rstrip("'",)
            if (root / reference).is_file():
                if reference not in seen: pending.append(reference)
            else: missing.add(reference)
rows = []
for path in sorted(seen):
    source = root / path; data = source.read_bytes(); archived = destination / 'files' / path
    archived.parent.mkdir(parents=True, exist_ok=True); shutil.copyfile(source, archived)
    archived.chmod(source.stat().st_mode & 0o777)
    assert archived.read_bytes() == data
    rows.append({'path': path, 'archived_path': str(archived.relative_to(destination)),
                 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                 'mode': source.stat().st_mode & 0o777})
manifest = {'schema_version': 1, 'captured_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'checkout': str(root), 'variant': 'king',
            'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
            'shared_runtime_publication': '6718844ff429821b031ab98a232026cf1a2d7cba',
            'scope': 'Fresh prequeue original bytes for the affected L4 component. Existing L3 transport seed paths reused only as a bounded input selection, then read/copy current bytes; explicit new King actor/art/paired component/scene/test/manifest/query/private-runner/config seeds and literal res references added. Extra prior unexecuted test seeds may exist. Not a complete Godot engine/globalclass/dynamic resource graph and not evidence that all inputs execute. No native/pass credit, no later UID/source backfill.',
            'seeds': sorted(seed_paths), 'missing_literal_references': sorted(missing), 'files': rows}
(destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps({'archive': str(destination), 'files': len(rows), 'bytes': sum(r['bytes'] for r in rows),
                  'manifest_sha256': hashlib.sha256((destination / 'manifest.json').read_bytes()).hexdigest()}))
