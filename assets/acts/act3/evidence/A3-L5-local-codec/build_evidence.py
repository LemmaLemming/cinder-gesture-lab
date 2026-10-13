"""Build portable custody from explicitly closed local-codec runs only.

No engine, tracked source edits, allocation, or active-source read is performed.
Root supplies closure-authorized.json before --seal; --stage-three never reads
the fourth run. External sibling references resolve after Root publication.
"""
from pathlib import Path
import argparse
import datetime
import difflib
import gzip
import hashlib
import json
import re
import shlex
import shutil

ROOT = Path.cwd().resolve()
OUT = ROOT / '.cinder/a3-l5-local-codec-evidence-plan'
EVIDENCE = ROOT / 'assets/acts/act3/evidence'
PRIOR = {
    'A3-L5-first-capture-rule': '451eab12e4532df84e90d9cde5320fc1ee3824d6f89756f805a1ddf6895ee1ac',
    'A3-L5-public-clock-join': '0f01194ae5bbbf4abbbfe16deee790a4d224fffdd7295fec7b75a4e5d0e4b059',
    'A3-L5-native-portraits': 'e1f8bc55065b4006e7249a252e75420ea12814c6cdb775b6bc08993c2b61a165',
    'A3-L5-two-slot-rule': '53be11ab68f72cdee375540e4ff6d459423b565f0d8d0c96924b464df3c7cba9',
}
RUNS = [
    ('crystalman-codec-v3-import-native', 'closed_clean_import'),
    ('crystalman-codec-v3-one-first-native', 'closed_original_unsupported_material_property_failure'),
    ('crystalman-codec-grow-corrected-one-native', 'closed_clean_local_codec_capacity1'),
    ('crystalman-codec-grow-corrected-two-native', 'closed_clean_local_codec_capacity2'),
]
SOURCE_KEYS = [
    'tests/acts/act3/fixtures/captured_rule_room_codec.gd',
    'tests/acts/act3/fixtures/captured_rule_codec_room.gd',
    'tests/acts/act3/captured_rule_save_codec_smoke.gd',
    'tests/acts/act3/fixtures/captured_rule_codec_one.tscn',
    'tests/acts/act3/fixtures/captured_rule_codec_two.tscn',
]
CACHE = {}


def digest(path):
    path = path.resolve()
    stat = path.stat()
    key = str(path), stat.st_size, stat.st_mtime_ns
    if key not in CACHE:
        h = hashlib.sha256()
        with path.open('rb') as f:
            for block in iter(lambda: f.read(1048576), b''):
                h.update(block)
        CACHE[key] = h.hexdigest()
    return CACHE[key]


def within(path, root):
    path = path.resolve()
    assert path.is_relative_to(root.resolve()), ('path escape', path, root)
    return path


def record(path):
    return {'path': path.relative_to(OUT).as_posix(), 'bytes': path.stat().st_size,
            'sha256': digest(path)}


def exact(src, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        assert dest.stat().st_size == src.stat().st_size and digest(dest) == digest(src), ('custody would change', dest)
    else:
        shutil.copy2(src, dest)
    assert dest.stat().st_size == src.stat().st_size and digest(dest) == digest(src)


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + '.tmp')
    tmp.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')
    tmp.replace(path)


def read_json(path):
    return json.loads(path.read_text())


def build(seal):
    assert not (OUT / 'READY.json').exists(), 'sealed packet is immutable'
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / '.gdignore').write_bytes(b'')
    selected = RUNS if seal else RUNS[:3]
    authorization = None
    if seal:
        authorization = read_json(OUT / 'closure-authorized.json')
        assert authorization['root_reported_all_required_jobs_closed'] is True
        assert set(authorization['raw_log_sha256']) == {name for name, _ in RUNS}

    catalogue = {}
    prior_checks = []
    prior_refs = 0
    for name, pin in PRIOR.items():
        packet = EVIDENCE / name
        assert digest(packet / 'index.json') == pin, ('prior index', name)
        index = read_json(packet / 'index.json')
        for a in index['artifacts']:
            p = within(packet / a['path'], EVIDENCE)
            assert p.is_file() and p.stat().st_size == a['bytes'] and digest(p) == a['sha256'], ('prior artifact', name, a['path'])
            if a['path'].startswith('source-blobs/'):
                catalogue.setdefault(a['sha256'], {'packet_path': '../' + name + '/' + a['path'],
                    'bytes': a['bytes'], 'sha256': a['sha256'],
                    'packet_index_path': '../' + name + '/index.json', 'packet_index_sha256': pin})
        maps = []
        for p in sorted(packet.rglob('source-map.json')):
            mapping = read_json(p)
            assert mapping.get('source_count', len(mapping['sources'])) == len(mapping['sources'])
            for a in mapping['sources']:
                q = within(packet / a['packet_path'], EVIDENCE)
                assert q.is_file() and q.stat().st_size == a['bytes'] and digest(q) == a['sha256'], ('prior source', p, a['packet_path'])
                physical = q.relative_to(EVIDENCE).as_posix()
                owner = physical.split('/')[0]
                catalogue.setdefault(a['sha256'], {'packet_path': '../' + physical,
                    'bytes': a['bytes'], 'sha256': a['sha256'],
                    'packet_index_path': '../' + owner + '/index.json',
                    'packet_index_sha256': digest(EVIDENCE / owner / 'index.json')})
            prior_refs += len(mapping['sources'])
            maps.append({'path': p.relative_to(packet).as_posix(),
                         'source_count': len(mapping['sources']), 'sha256': digest(p)})
        for a in index.get('prior_packet_indices', []):
            assert digest(within(packet / a['path'], EVIDENCE)) == a['sha256']
        prior_checks.append({'path': '../' + name + '/index.json', 'sha256': pin,
            'artifact_count_verified': len(index['artifacts']), 'source_maps_verified': maps})

    new_blobs = set()
    sources = 0
    external = 0
    records = []
    for name, classification in selected:
        src = ROOT / '.cinder' / name
        result = read_json(src / 'result.json')
        freeze = read_json(src / 'source-freeze.json')
        assert result['closed_at'] and result['original_source_changes'] == []
        assert result['frozen_inputs'] == len(freeze['sources'])
        assert freeze['baseline'] == '00635be0456df5ac3e0eacdd9f8b08dbe4223fc4'
        assert freeze['api_revision'] == 'campaign-shared-54'
        target = OUT / 'runs' / name
        for filename in ['result.json', 'source-freeze.json']:
            exact(src / filename, target / filename)
        command_original = (src / 'command.json').is_file()
        command_filename = 'command.json' if command_original else 'command-derived.json'
        if command_original:
            exact(src / 'command.json', target / command_filename)
        else:
            write_json(target / command_filename, {
                'status': 'DERIVED_FROM_UNCHANGED_ORIGINAL_RESULT_NOT_AN_ORIGINAL_COMMAND_FILE',
                'command': result['command'], 'argv': shlex.split(result['command']),
                'original_result_sha256': digest(src / 'result.json'),
                'original_command_json_present': False,
                'note': 'The owner runner did not emit command.json for this run. Exact command string is preserved in the original result; no start time is invented.'})
        mapping = []
        for logical, sha in freeze['sources'].items():
            original = within(src / 'sources' / logical, src / 'sources')
            assert digest(original) == sha, ('frozen source', name, logical)
            if sha not in catalogue:
                rel = 'source-blobs/' + sha + '/' + Path(logical).name
                exact(original, OUT / rel)
                catalogue[sha] = {'packet_path': rel, 'bytes': original.stat().st_size, 'sha256': sha}
                new_blobs.add(sha)
            ref = catalogue[sha]
            assert original.stat().st_size == ref['bytes']
            mapping.append({'original_logical_path': logical,
                'original_frozen_path': '.cinder/' + name + '/sources/' + logical, **ref})
            sources += 1
            external += int(ref['packet_path'].startswith('../'))
        write_json(target / 'source-map.json', {'schema_version': 1, 'source_count': len(mapping),
            'resolution': 'packet_path is relative to published packet root; sibling indices are hash pinned',
            'sources': mapping})
        raw = src / 'native.log'
        raw_sha = digest(raw)
        assert raw_sha == result['raw_log_sha256']
        if seal:
            assert raw_sha == authorization['raw_log_sha256'][name]
        if raw.stat().st_size > 8 * 1048576:
            gz = target / 'native.log.gz'
            if not gz.exists():
                with raw.open('rb') as inp, gz.open('wb') as out:
                    with gzip.GzipFile(filename='', mode='wb', compresslevel=6, fileobj=out, mtime=0) as z:
                        shutil.copyfileobj(inp, z, 1048576)
            h = hashlib.sha256()
            size = 0
            with gzip.open(gz, 'rb') as f:
                for chunk in iter(lambda: f.read(1048576), b''):
                    size += len(chunk)
                    h.update(chunk)
            assert size == raw.stat().st_size and h.hexdigest() == raw_sha
            log = {'portable_path': gz.relative_to(OUT).as_posix(), 'encoding': 'gzip',
                'compressed_bytes': gz.stat().st_size, 'compressed_sha256': digest(gz),
                'decompressed_original_bytes': size, 'decompressed_original_sha256': raw_sha,
                'original_preserved_unchanged': True, 'decompression_verified': True}
            write_json(target / 'native-log-encoding.json', log)
        else:
            exact(raw, target / 'native.log')
            log = {'portable_path': (target / 'native.log').relative_to(OUT).as_posix(),
                'encoding': 'identity', 'original_bytes': raw.stat().st_size, 'original_sha256': raw_sha}
        passes = 0
        script_errors = 0
        diagnostic_count = 0
        failures = []
        footers = []
        with raw.open(errors='replace') as f:
            for line_no, line in enumerate(f, 1):
                passes += int(line.startswith('PASS:'))
                script_errors += int(line.startswith('SCRIPT ERROR:'))
                diagnostic_count += int(line.startswith(('SCRIPT ERROR:', 'ERROR:', 'WARNING:')))
                if 'FAIL:' in line:
                    failures.append({'line': line_no, 'text': line.rstrip()})
                if line.startswith('Captured rule local codec draft:'):
                    footers.append(line.rstrip())
        assert footers == result.get('footers', [])
        if classification.startswith('closed_clean'):
            assert result['exit_code'] == 0 and result['diagnostics'] == [] and diagnostic_count == 0
        parsed = re.search(r'capacity(\d+), (\d+) checks; failures(\d+); post-actor ticks(\d+); native samples(\[.*?\])\.', footers[-1]) if footers else None
        if 'local_codec_capacity' in classification:
            assert parsed and int(parsed[3]) == 0
        records.append({'name': name, 'classification': classification,
            'original_directory': '.cinder/' + name,
            'result_path': 'runs/' + name + '/result.json',
            'command_path': 'runs/' + name + '/' + command_filename,
            'command_json_original_present': command_original,
            'manifest_path': 'runs/' + name + '/source-freeze.json',
            'source_map_path': 'runs/' + name + '/source-map.json',
            'closed_at_original': result['closed_at'], 'exit_code': result['exit_code'],
            'command': result['command'], 'source_count': len(mapping),
            'baseline': freeze['baseline'], 'api_revision': freeze['api_revision'],
            'owned_head_original': freeze['owned_head'],
            'test_resource_sha256': {p: freeze['sources'][p] for p in SOURCE_KEYS},
            'production_max2_runtime_sha256': freeze['sources']['scripts/acts/act3/crystalman_rule_room.gd'],
            'footers': footers, 'capacity': int(parsed[1]) if parsed else None,
            'checks': int(parsed[2]) if parsed else None, 'failures': int(parsed[3]) if parsed else None,
            'actual_post_actor_ticks': int(parsed[4]) if parsed else None,
            'native_samples': json.loads(parsed[5]) if parsed else [],
            'pass_lines': passes, 'script_error_diagnostic_lines': script_errors,
            'error_or_warning_diagnostic_lines': diagnostic_count, 'failure_lines': failures,
            'original_source_changes': [], 'log': log})
        print('Preserved closed run:', name, len(mapping), flush=True)

    for name in ['a3-l5-captured-codec-v3-publication', 'a3-l5-captured-codec-final-review',
                 'a3-l5-design-validation-20261013']:
        src = ROOT / '.cinder' / name
        for p in sorted(src.rglob('*')):
            if p.is_file():
                exact(p, OUT / ('audits' if 'review' in name else 'custody') / name / p.relative_to(src))
    exact(ROOT / '.cinder/crystalman-codec-grow-correction-review.json',
          OUT / 'audits/crystalman-codec-grow-correction-review.json')
    exact(ROOT / '.cinder/youtube-access-retry-d6d75dcf-140c-4bc8-a84e-73df3a7e6ccb.json',
          OUT / 'research/youtube-access-retry-d6d75dcf-140c-4bc8-a84e-73df3a7e6ccb.json')
    exact(ROOT / 'docs/acts/act3/A3_L5_LOCAL_CODEC_NATIVE_20261013.md',
          OUT / 'custody/A3_L5_LOCAL_CODEC_NATIVE_20261013-original.md')
    pub = ROOT / '.cinder/a3-l5-captured-codec-v3-publication'
    custody = read_json(pub / 'custody.json')
    for a in custody['files']:
        p = pub / 'sources' / a['path']
        assert p.stat().st_size == a['bytes'] and digest(p) == a['sha256']
    prior_uids = read_json(pub / 'prior-uids.json')
    imp = read_json(ROOT / '.cinder/crystalman-codec-v3-import-native/result.json')
    assert len(prior_uids) == imp['prior_uid_count'] == 468 and imp['prior_uid_changes'] == []
    assert all(imp['all_current_uid_sha256'].get(k) == v for k, v in prior_uids.items())
    assert imp['current_uid_count'] == 471 and imp['duplicate_uid_values'] == [] and len(imp['new_uid_paths']) == 3
    genuine_uids = []
    for p in imp['new_uid_paths']:
        frozen = ROOT / '.cinder/crystalman-codec-v3-one-first-native/sources' / p
        assert digest(frozen) == imp['all_current_uid_sha256'][p]
        genuine_uids.append({'path': p, 'sha256': digest(frozen)})

    fix = read_json(ROOT / '.cinder/crystalman-codec-grow-correction-review.json')
    assert fix['native_log_sha256'] == records[1]['log']['original_sha256']
    assert records[1]['script_error_diagnostic_lines'] == 174
    assert records[1]['checks'] == 187 and records[1]['failures'] == 1
    fix_paths = fix['changed_files']
    corrections = []
    patch = []
    for logical in fix_paths:
        before = ROOT / '.cinder/crystalman-codec-v3-one-first-native/sources' / logical
        after = ROOT / '.cinder/crystalman-codec-grow-corrected-one-native/sources' / logical
        old, new = before.read_bytes(), after.read_bytes()
        assert old.count(b'grow_enabled') == 1 and old.replace(b'grow_enabled', b'grow') == new
        corrections.append({'path': logical, 'before_sha256': digest(before), 'after_sha256': digest(after),
                            'only_change': 'one grow_enabled property token replaced by documented grow'})
        patch.extend(difflib.unified_diff(old.decode().splitlines(keepends=True),
            new.decode().splitlines(keepends=True), fromfile='before/' + logical, tofile='after/' + logical))
    (OUT / 'custody/grow-property-only.patch').write_text(''.join(patch))
    write_json(OUT / 'custody/grow-property-correction-verification.json', {'fix_receipt_sha256': digest(ROOT / '.cinder/crystalman-codec-grow-correction-review.json'),
        'exactly_two_property_tokens_changed': True, 'unchanged_guard_values_and_assertions': True,
        'files': corrections})
    validators = read_json(ROOT / '.cinder/a3-l5-design-validation-20261013/result.json')
    for name, a in validators['results'].items():
        assert a['exit_code'] == 0 and digest(ROOT / a['log']) == a['sha256']

    verification = {'status': 'ALL_SELECTED_CLOSED_ORIGINALS_AND_PORTABLE_REFERENTS_VERIFIED',
        'only_closed_runs': True, 'active_source_read': False,
        'root_reported_all_required_jobs_closed': seal,
        'prior_packet_checks': prior_checks, 'prior_packet_source_referents_verified': prior_refs,
        'new_run_source_references_verified': sources, 'external_same_byte_source_references': external,
        'new_unique_source_blobs': len(new_blobs), 'prior_uids_verified_exact': 468,
        'genuine_new_uids': genuine_uids, 'current_unique_uids': 471,
        'publication_original_source_bytes_verified': True,
        'two_only_material_property_token_corrections_verified': True,
        'required_design_validators_exit0_and_log_hashes_verified': True,
        'no_whole_parent_or_campaign_or_art_acceptance': True}
    write_json(OUT / 'verification.json', verification)
    rows = '\n'.join('| ' + r['name'] + ' | ' + str(r['exit_code']) + ' | ' + str(r['checks']) + '/' + str(r['failures']) + ' | ' + str(r['actual_post_actor_ticks']) + ' | ' + str(r['source_count']) + ' |' for r in records)
    (OUT / 'README.md').write_text('''# A3-L5 local captured-rule codec evidence

This packet preserves explicitly closed native originals for a test-only recipient
with its own 12×16 floor. It qualifies the original self-floor unit codec and quiet
fresh candidate validation. The live production max2 rule room still refuses whole
transport; this packet does not establish a complete Crystalman level.

| Original run | Exit | Checks/failures | Actual post-actor ticks | Frozen inputs |
| --- | --- | --- | --- | --- |
''' + rows + '''

The first capacity1 run retains its original 187 checks, one failure and 174 script
errors from unsupported StandardMaterial3D.grow_enabled. Its snapshot/optical results
before that validation abort are not reclassified as passes. The correction uses
the documented grow property and changes exactly two property tokens, preserving
the false-value guard and exact donor-material receipt. The official references and
original failure command, revision, error and hash are preserved in the audit.

Corrected capacity1 and capacity2 results qualify only the actual samples listed in
their original native footers: independent quiet fresh recipients, the authoritative
outer Player, whole Gate and Scheduler, projected Playback, exact JSON/file roundtrip,
original clocks/history/lease/event identities, native candidate presentation with
actual alpha and cull-mask negatives, consumed GUI Resume and normal disposal.
Capture restoration does not arm, admit, reprove, consume, rebind or repair clocks.

Every command, result, source freeze and raw log remains byte-exact. Hash-keyed source
blobs preserve every original frozen logical path while deduplicating identical
bytes against four earlier pinned evidence packets. New Shared54 input bytes are
stored in this packet. Resolve source-map packet_path relative to the published
packet root. For this ignored draft, ../A3-L5-* paths instead resolve under the
existing assets/acts/act3/evidence directory. The complete earlier artifact and source
referent verification is recorded in verification.json. Original source-only comments
are retained unchanged and qualified by the native result scope, not edited into
acceptance claims. Raw logs are copied unchanged; logs above 8 MiB use lossless gzip
with original/compressed hashes and independently verified decompression.
For corrected runs whose original runner did not write command.json, a clearly
marked command-derived.json cites the exact unchanged original result containing
the command string; no original file or start time is invented.

The latest YouTube access-retry receipt is retained unchanged as research custody.
It is not inspected-footage evidence and grants no art or gameplay credit.

The single required import retains 468 prior UID bytes exactly and records three
genuine generated test-script UIDs, giving 471 unique values and zero collisions.
Import success does not establish native codec behavior. The three current canonical
design validators passed; their original logs and explicit unsimulated limits are
included as design validation only, with no new allocation or runtime/art/balance
credit.

Not covered: an external parent floor, live regular-enemy Scheduler3, full level
phase transitions, idle framing art without an inert original recipient, whole
campaign Store/Save/Continue/Retry, full layout or production art, graphical max2
acceptance, broad loadout validation, human balance, a full playthrough, campaign
registration or full A3-L5 acceptance. Root owns publication and commits.
''')
    excluded = {'index.json', 'index.DRAFT.json', 'READY.json', 'DRAFT_STATUS.json'}
    artifacts = [record(p) for p in sorted(OUT.rglob('*')) if p.is_file() and p.relative_to(OUT).as_posix() not in excluded]
    index = {'schema_version': 1, 'level_id': 'A3-L5',
        'created_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'scope': 'Test-only original self-floor local captured-rule codec; retained original property failure and corrected capacity1/2; no full parent/campaign/art acceptance.',
        'baseline': '00635be0456df5ac3e0eacdd9f8b08dbe4223fc4', 'api_revision': 'campaign-shared-54',
        'all_required_runs_closed_and_root_reported': seal, 'prior_packet_indices': prior_checks,
        'runs': records, 'source_reference_count': sources,
        'external_same_byte_source_references': external, 'new_unique_source_blobs': len(new_blobs),
        'artifact_count_excluding_index_and_READY': len(artifacts), 'artifacts': artifacts,
        'limitations': ['test-only recipient', 'original self-floor unit only', 'no full parent/campaign Save/Continue/Retry',
            'no production art or graphical max2 acceptance', 'no full A3-L5 acceptance']}
    for a in artifacts:
        p = within(OUT / a['path'], OUT)
        assert p.stat().st_size == a['bytes'] and digest(p) == a['sha256']
    for r in records:
        mapping = read_json(OUT / r['source_map_path'])
        for a in mapping['sources']:
            p = EVIDENCE / a['packet_path'][3:] if a['packet_path'].startswith('../') else OUT / a['packet_path']
            assert p.stat().st_size == a['bytes'] and digest(p) == a['sha256']
            if 'packet_index_path' in a:
                assert digest(EVIDENCE / a['packet_index_path'][3:]) == a['packet_index_sha256']
    index_path = OUT / ('index.json' if seal else 'index.DRAFT.json')
    write_json(index_path, index)
    status = {'status': 'READY_FOR_ROOT_REVIEW_AND_PUBLICATION' if seal else 'STAGED_THREE_CLOSED_RUNS_AWAITING_ROOT_CAPACITY2_CLOSURE',
        'stage_root': str(OUT), 'index_sha256': digest(index_path), 'source_reference_count': sources,
        'artifact_count_excluding_index_and_READY': len(artifacts), 'new_unique_source_blobs': len(new_blobs),
        'external_same_byte_source_references': external, 'active_source_read': False,
        'owned_edits': False, 'engine_or_UID_or_allocation': False,
        'all_required_runs_closed_and_root_reported': seal,
        'original_failure_and_all_source_bytes_retained': True, 'all_referents_verified': True,
        'scope': 'test-only local codec evidence; no full level/campaign/art acceptance'}
    if seal:
        for name in ['index.DRAFT.json', 'DRAFT_STATUS.json']:
            p = OUT / name
            if p.exists():
                p.unlink()
        write_json(OUT / 'READY.json', status)
    else:
        write_json(OUT / 'DRAFT_STATUS.json', status)
    print(json.dumps(status, indent=2), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--stage-three', action='store_true')
    group.add_argument('--seal', action='store_true')
    build(parser.parse_args().seal)
