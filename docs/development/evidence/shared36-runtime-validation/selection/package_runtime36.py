"""Copy explicitly selected CLOSED originals. Never launch an engine or edit old packs."""
from pathlib import Path, PurePosixPath
from datetime import datetime, timezone
import argparse
import hashlib
import json
import re
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DEST = 'docs/development/evidence/shared36-runtime-validation'
SUMMARY = re.compile(r'\b(\d+)\s+checks\s*,\s*(\d+)\s+failures\b')
SCRIPT_ERROR = re.compile(r'^\s*SCRIPT ERROR:', re.M)
ALL_ERROR = re.compile(r'^\s*(?:SCRIPT )?ERROR:', re.M)
LOAD_FAILURE = re.compile(r'Parse Error|Compilation failed|Failed to load script|Error loading script', re.I)
LITERAL_RES = re.compile(r'''res://([^\s"'\)]+)''')
MARKDOWN_LINK = re.compile(r'!?\[[^\]\n]*\]\((<[^>]+>|[^\n)]+)\)')
SHA = re.compile(r'[0-9a-f]{64}')
NAME = re.compile(r'[a-z0-9][a-z0-9-]{0,95}')


def require(value, message):
    if not value:
        raise ValueError(message)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def relative(value):
    require(type(value) is str and value, 'Nonempty relative String path required')
    p = PurePosixPath(value)
    require(not p.is_absolute() and '..' not in p.parts and str(p) == value,
            'Unsafe/noncanonical path: ' + value)
    return value


def original_file(rel):
    path = ROOT / relative(rel)
    # Reject a symlink in any component, not merely the final file.
    current = ROOT
    for part in PurePosixPath(rel).parts:
        current /= part
        require(not current.is_symlink(), 'Linked original: ' + rel)
    require(path.is_file(), 'Original missing: ' + rel)
    return path


def read_original(rel, expected=None):
    path = original_file(rel)
    raw = path.read_bytes()
    if expected is not None:
        require(type(expected.get('bytes')) is int and expected['bytes'] >= 0 and
                len(raw) == expected['bytes'], 'Original byte count differs: ' + rel)
        require(type(expected.get('sha256')) is str and SHA.fullmatch(expected['sha256']) and
                digest(raw) == expected['sha256'], 'Original SHA differs: ' + rel)
    return raw


def json_value(raw):
    def pairs(items):
        out = {}
        for key, value in items:
            require(key not in out, 'Duplicate JSON key: ' + key)
            out[key] = value
        return out

    def invalid_constant(value):
        raise ValueError('Nonfinite JSON constant: ' + value)

    require(len(raw) <= 32 * 1024 * 1024, 'Receipt/configuration exceeds 32 MiB bound')
    return json.loads(raw.decode('utf-8'), object_pairs_hook=pairs,
                      parse_constant=invalid_constant)


def timestamp(value, label):
    require(type(value) is str, label + ' timestamp missing')
    date = datetime.fromisoformat(value)
    require(date.utcoffset() is not None, label + ' timestamp lacks timezone')
    return date


def diagnostics(raw):
    text = raw.decode('utf-8')
    summaries = [list(map(int, pair)) for pair in SUMMARY.findall(text)]
    return dict(completed_summaries=summaries,
                last_summary=summaries[-1] if summaries else None,
                script_error_lines=len(SCRIPT_ERROR.findall(text)),
                all_error_lines=len(ALL_ERROR.findall(text)),
                parse_or_load_failure=any(LOAD_FAILURE.search(line) and
                                          (ALL_ERROR.match(line) or re.match(r'^\s*(?:Parse Error|Compilation failed)', line))
                                          for line in text.splitlines()),
                observed_ca_startup_locations=text.count('platform/macos/os_macos.mm:1035'))


def classify(exit_code, log_diagnostics):
    values = list(log_diagnostics.values())
    summaries = [item['last_summary'] for item in values]
    if (any(item['script_error_lines'] or item['parse_or_load_failure'] for item in values) or
            any(item is None or item[0] == 0 for item in summaries) or summaries[0] != summaries[1]):
        return 'INVALID_no_execution_credit'
    if exit_code != 0 or summaries[0][1] != 0:
        return 'FAILED_no_pass_credit'
    if any(item['all_error_lines'] for item in values):
        return 'ZERO_ASSERTION_FAILURES_native_diagnostics_need_review'
    return 'CLOSED_zero_failures_no_detected_errors'


def preflight_run(spec):
    require(type(spec) is dict, 'Run specification must be Dictionary')
    name = spec.get('id')
    require(type(name) is str and NAME.fullmatch(name), 'Unsafe/absent run name')
    script = relative(spec.get('script'))
    expected_manifest = spec.get('manifest_sha256')
    require(type(expected_manifest) is str and SHA.fullmatch(expected_manifest),
            'Explicit original manifest SHA required: ' + name)
    count = spec.get('source_count')
    require(type(count) is int and 0 < count <= 20000, 'Explicit bounded source count required: ' + name)
    closure_rel = '.cinder/' + name + '-closure.json'
    closure_raw = read_original(closure_rel)
    closure = json_value(closure_raw)
    require(type(closure) is dict, 'Closure must be Dictionary: ' + name)
    closed_at = timestamp(closure.get('closed_at'), 'Closure ' + name)
    require(type(closure.get('exit_code')) is int, 'Actual exit missing: ' + name)
    manifest_rel = '.cinder/' + name + '-source/manifest.json'
    manifest_raw = read_original(manifest_rel)
    require(digest(manifest_raw) == expected_manifest == closure.get('manifest_sha256'),
            'Original/closure/selected manifest SHA mismatch: ' + name)
    manifest = json_value(manifest_raw)
    require(type(manifest) is dict and manifest.get('canonical_root') == str(ROOT),
            'Foreign original canonical root: ' + name)
    if 'captured_at' in manifest:
        require(timestamp(manifest['captured_at'], 'Capture ' + name) <= closed_at,
                'Capture postdates closure: ' + name)
    entries = manifest.get('files')
    require(type(entries) is list and len(entries) == count, 'Source membership count differs: ' + name)
    require(type(closure.get('original_and_live_sources_verified')) is int and
            closure['original_and_live_sources_verified'] == count,
            'Closure source verification count differs: ' + name)
    source_root_rel = '.cinder/' + name + '-source'
    originals = {'manifest.json': (manifest_rel, manifest_raw)}
    source_paths, literals = set(), set()
    for entry in entries:
        require(type(entry) is dict, 'Source entry must be Dictionary: ' + name)
        rel, archived = relative(entry.get('path')), relative(entry.get('archived_path'))
        require(archived == 'files/' + rel and rel not in source_paths,
                'Source alias/duplicate: ' + name + ':' + rel)
        raw = read_original(source_root_rel + '/' + archived, entry)
        source_paths.add(rel)
        originals[archived] = (source_root_rel + '/' + archived, raw)
        if Path(rel).suffix in ('.gd', '.tscn', '.tres'):
            literals.update(LITERAL_RES.findall(raw.decode('utf-8')))
    seeds = manifest.get('seeds')
    require(type(seeds) is list and script in seeds and script in source_paths,
            'Selected executed script is not an original seed: ' + name)
    source_root = ROOT / source_root_rel
    require(not any(p.is_symlink() for p in source_root.rglob('*')), 'Linked source member: ' + name)
    members = {p.relative_to(source_root).as_posix() for p in source_root.rglob('*') if p.is_file()}
    require(members == set(originals), 'Missing/extra original source member: ' + name)
    expected_logs = {'.cinder/' + name + '.log', '.cinder/' + name + '-wrapper.log'}
    log_entries = closure.get('logs')
    require(type(log_entries) is list and len(log_entries) == 2 and
            all(type(entry) is dict for entry in log_entries) and
            {entry.get('path') for entry in log_entries} == expected_logs,
            'Full native/wrapper log membership differs: ' + name)
    logs, counted = {}, {}
    for entry in log_entries:
        rel = relative(entry['path'])
        raw = read_original(rel, entry)
        stats = diagnostics(raw)
        for key, observed in (('script_errors', stats['script_error_lines']),
                              ('native_errors', stats['all_error_lines'])):
            if key in entry:
                require(type(entry[key]) is int and entry[key] == observed,
                        'Closure/log diagnostic count mismatch: ' + rel + ':' + key)
        logs[rel] = raw
        counted[rel] = stats
    if 'expected_result' in spec:
        expected = spec['expected_result']
        require(type(expected) is list and len(expected) == 2 and
                all(type(item) is int and item >= 0 for item in expected), 'Bad selected result: ' + name)
        require(all(item['last_summary'] == expected for item in counted.values()),
                'Selected completed result differs: ' + name)
    if 'expected_exit_code' in spec:
        require(type(spec['expected_exit_code']) is int and closure['exit_code'] == spec['expected_exit_code'],
                'Selected actual exit differs: ' + name)
    provenance = []
    receipt_entries = spec.get('original_receipts', [])
    require(type(receipt_entries) is list and len(receipt_entries) <= 64,
            'Original receipts must be bounded explicit List: ' + name)
    for entry in receipt_entries:
        require(type(entry) is dict and entry.get('role') in ('submission', 'report', 'observation'),
                'Original receipt must declare submission/report/observation role: ' + name)
        rel = relative(entry.get('path'))
        raw = read_original(rel, entry)
        # Optional explicit joins are verified, not inferred from a filename.
        joins = entry.get('json_joins', {})
        require(type(joins) is dict, 'Receipt joins must be Dictionary: ' + rel)
        if joins:
            value = json_value(raw)
            for key, join in joins.items():
                require(join in ('manifest_sha256', 'native_log_sha256', 'wrapper_log_sha256', 'run_id'),
                        'Unsupported receipt join: ' + rel)
                expected = {'manifest_sha256': expected_manifest, 'run_id': name,
                            'native_log_sha256': digest(logs['.cinder/' + name + '.log']),
                            'wrapper_log_sha256': digest(logs['.cinder/' + name + '-wrapper.log'])}[join]
                require(type(value) is dict and value.get(key) == expected,
                        'Original receipt identity join differs: ' + rel + ':' + key)
        provenance.append(dict(origin=rel, raw=raw, role=entry['role'], verified_json_joins=joins))
    classification = classify(closure['exit_code'], counted)
    return dict(id=name, script=script, closure=closure, closure_origin=closure_rel,
                closure_raw=closure_raw, manifest=manifest, manifest_sha256=expected_manifest,
                originals=originals, logs=logs, diagnostics=counted, classification=classification,
                original_receipts=provenance, selected_note=spec.get('note'),
                literal_res_included=sorted(literals & source_paths),
                literal_res_not_in_original_subset=sorted(literals - source_paths))


def markdown_anchors(raw):
    used, anchors = {}, set()
    for line in raw.decode('utf-8').splitlines():
        match = re.match(r'^#{1,6}\s+(.+?)\s*#*$', line)
        if match:
            slug = re.sub(r'[^\w\- ]', '', match[1].lower()).replace(' ', '-')
            number = used.get(slug, 0)
            used[slug] = number + 1
            anchors.add(slug + ('-' + str(number) if number else ''))
    return anchors


def check_links(document_rel, raw, planned):
    results = []
    for match in MARKDOWN_LINK.finditer(raw.decode('utf-8')):
        value = match[1]
        target = value[1:-1] if value.startswith('<') else value.split(' "', 1)[0]
        if re.match(r'^[A-Za-z][A-Za-z0-9+.-]*:', target) or target.startswith('//'):
            continue
        file_part, separator, anchor = unquote(target).partition('#')
        if file_part.startswith('/'):
            path = Path(file_part)
        else:
            path = ROOT / Path(document_rel).parent / file_part
        normalized = path.resolve()
        require(normalized.is_relative_to(ROOT), 'Publication link escapes project: ' + target)
        rel = normalized.relative_to(ROOT).as_posix()
        if rel in planned:
            linked = planned[rel]
            scope = 'planned_new_archive_member'
        else:
            linked = read_original(rel)
            scope = 'existing_project_file'
        if separator and anchor and Path(rel).suffix == '.md':
            require(anchor in markdown_anchors(linked), 'Publication Markdown anchor missing: ' + target)
        results.append(dict(target=target, resolved_path=rel, scope=scope))
    return results


def README(scopes):
    lines = ['# Shared36 runtime validation originals', '',
             'Generated from an explicit root-selected job list after each original process closed. '
             'This archive preserves original bytes; it does not publish an API or accept campaign content.', '',
             '| Original job | Printed checks / failures | Exit | Independent log classification |',
             '| --- | --- | --- | --- |']
    for scope in scopes:
        name = scope['id']
        value = scope['diagnostics']['.cinder/' + name + '.log']['last_summary']
        result = '/'.join(map(str, value)) if value else 'No completed summary'
        lines.append('| [' + name + '](logs/' + name + '.log) | ' + result + ' | ' +
                     str(scope['closure']['exit_code']) + ' | ' + scope['classification'] + ' |')
    lines.extend(['', 'Every row retains a [source manifest](index.json), full native and wrapper logs, '
                  'and an original CLOSED receipt. Submission/report receipts are copied only when explicitly '
                  'selected and available; missing argv, session or permission provenance remains unknown.', '',
                  'Zero assertion failures with native ERROR diagnostics need separate review. Script, parse, '
                  'load errors, missing summaries and inconsistent logs receive no execution credit; exit zero '
                  'alone is insufficient. Failed and invalid originals remain separate from corrected runs.', '',
                  'The source groups are bounded original literal subsets, not a full engine import/resource '
                  'graph. Absent literals and later UIDs are listed without filling them. No performance, FPS, '
                  'human-input, authored-level, portrait, export or release claim is inferred by this builder.', '',
                  'Publication document links were checked read-only. Earlier Shared35 archives are neither '
                  'rewritten nor reattributed. Native private-field/read-only custody and runtime safety require '
                  'the separately reviewed implementation and targeted observations.', ''])
    return '\n'.join(lines).encode('utf-8')


def build(scopes, config_rel, config_raw, destination_rel, documents, execute):
    destination = ROOT / destination_rel
    current = ROOT
    for part in PurePosixPath(destination_rel).parts:
        current /= part
        require(not current.is_symlink(), 'Linked destination component: ' + str(current))
    require(not destination.exists(), 'Destination exists; never overwrite historical evidence')
    artifacts, payloads, source_groups, runs = [], {}, [], []

    def add(rel, raw, role, origin=None, group=None):
        relative(rel)
        require(rel not in payloads and rel != 'index.json', 'Archive member alias: ' + rel)
        payloads[rel] = raw
        item = dict(path=rel, bytes=len(raw), sha256=digest(raw), role=role,
                    origin_path=str(ROOT / origin) if origin else None)
        if group:
            item['source_group'] = group
        artifacts.append(item)

    # Insertion order is intentional: these guards are written before historical .gd bytes.
    add('.gdignore', b'', 'archive_import_exclusion')
    add('.gitattributes', b'sources/** -text -diff -whitespace\nlogs/** -text -diff -whitespace\nclosures/** -text -diff -whitespace\nsubmissions/** -text -diff -whitespace\nreports/** -text -diff -whitespace\nobservations/** -text -diff -whitespace\nselection/** -text -diff -whitespace\n', 'raw_archive_whitespace_preservation')
    add('selection/jobs.json', config_raw, 'packaging_selection_not_execution_submission', config_rel)
    builder_rel = Path(__file__).relative_to(ROOT).as_posix()
    add('selection/package_runtime36.py', read_original(builder_rel), 'offline_archive_builder', builder_rel)
    for scope in scopes:
        name = scope['id']
        for rel, (origin, raw) in scope['originals'].items():
            add('sources/' + name + '/' + rel, raw,
                'original_prequeue_manifest' if rel == 'manifest.json' else 'original_source', origin, name)
        closure_path = 'closures/' + name + '-closure.json'
        add(closure_path, scope['closure_raw'], 'original_process_closure', scope['closure_origin'], name)
        for origin, raw in scope['logs'].items():
            add('logs/' + Path(origin).name, raw,
                'full_wrapper_log' if origin.endswith('-wrapper.log') else 'full_native_log', origin, name)
        receipt_paths = []
        for ordinal, receipt in enumerate(scope['original_receipts']):
            folder = {'submission': 'submissions', 'report': 'reports', 'observation': 'observations'}[receipt['role']]
            rel = folder + '/' + name + '/' + str(ordinal) + '-' + Path(receipt['origin']).name
            add(rel, receipt['raw'], 'original_' + receipt['role'], receipt['origin'], name)
            receipt_paths.append(dict(path=rel, verified_json_joins=receipt['verified_json_joins']))
        source_groups.append(dict(id=name, manifest='sources/' + name + '/manifest.json',
                                  original_manifest_sha256=scope['manifest_sha256'],
                                  declared_file_count=len(scope['manifest']['files']),
                                  scope=scope['manifest'].get('scope'),
                                  literal_res_included=scope['literal_res_included'],
                                  literal_res_not_in_original_subset=scope['literal_res_not_in_original_subset'],
                                  graph_limit='Original bounded subset only; no later live byte or UID fills.'))
        closure = scope['closure']
        runs.append(dict(id=name, source_group=name, script=scope['script'],
                         selected_script_provenance='Root selection checked against original seed; exact argv not reconstructed',
                         closed=True, closed_at=closure['closed_at'], exit_code=closure['exit_code'],
                         classification=scope['classification'],
                         acceptance_credit=False,
                         acceptance_limit='Independent log classification only; implementation/semantic review remains external',
                         printed_native_summary=scope['diagnostics']['.cinder/' + name + '.log']['last_summary'],
                         independently_counted_diagnostics=scope['diagnostics'],
                         closure=closure_path, native_log='logs/' + name + '.log',
                         wrapper_log='logs/' + name + '-wrapper.log', original_receipts=receipt_paths,
                         scope=closure.get('scope'), selected_note=scope['selected_note'],
                         exact_argv=closure.get('argv'),
                         exact_argv_provenance='Original closure argv, if present; otherwise unknown',
                         session=closure.get('session'), permission_scope=closure.get('permission_scope'),
                         no_later_source_execution_credit=True))
    readme = README(scopes)
    add('README.md', readme, 'archive_scope_and_limits')
    planned = {destination_rel + '/' + rel: raw for rel, raw in payloads.items()}
    # The index is a planned generated member; links to it do not imply it existed before packaging.
    planned[destination_rel + '/index.json'] = b'{}\n'
    document_checks = []
    for rel in documents:
        raw = read_original(relative(rel))
        document_checks.append(dict(path=rel, bytes=len(raw), sha256=digest(raw),
                                    local_links=check_links(rel, raw, planned), rewritten=False))
    check_links(destination_rel + '/README.md', readme, planned)
    index = dict(schema_version=1, publication_status='archived_closed_originals_pending_independent_review',
                 created_at=datetime.now(timezone.utc).isoformat(),
                 scope='Explicit selected closed runtime validation originals only; no publication/engine/resource-graph claim',
                 source_file_count=sum(group['declared_file_count'] for group in source_groups),
                 source_groups=source_groups, runs=runs, publication_document_reference_checks=document_checks,
                 artifact_count=len(artifacts), artifacts=artifacts,
                 index_self_hash_policy='Index excluded from its own artifacts; report exact SHA externally')
    index_raw = (json.dumps(index, indent=2, ensure_ascii=False, allow_nan=False) + '\n').encode('utf-8')
    if execute:
        # Recheck every original immediately before creating any destination. Never consult live replacements.
        for item in artifacts:
            if item['origin_path']:
                origin = Path(item['origin_path'])
                require(origin.read_bytes() == payloads[item['path']], 'Original changed after preflight: ' + str(origin))
        for doc in document_checks:
            read_original(doc['path'], doc)
        destination.mkdir(parents=True)
        for rel, raw in payloads.items():
            target = destination / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(raw)
        (destination / 'index.json').write_bytes(index_raw)
        require({p.relative_to(destination).as_posix() for p in destination.rglob('*') if p.is_file()} ==
                set(payloads) | {'index.json'}, 'Post-copy membership differs')
        for item in artifacts:
            target = destination / item['path']
            require(not target.is_symlink() and target.read_bytes() == payloads[item['path']],
                    'Post-copy archived byte mismatch: ' + item['path'])
            if item['origin_path']:
                require(Path(item['origin_path']).read_bytes() == payloads[item['path']],
                        'Original changed during copy: ' + item['origin_path'])
        require((destination / 'index.json').read_bytes() == index_raw, 'Post-copy index differs')
    return dict(mode='archived' if execute else 'read_only_preflight', destination=destination_rel,
                run_count=len(scopes), source_file_count=index['source_file_count'],
                artifact_count=len(artifacts), index_sha256=digest(index_raw),
                classifications={scope['id']: scope['classification'] for scope in scopes},
                publication_documents_checked=len(document_checks))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', required=True, help='Existing root-selected relative JSON selection file')
    parser.add_argument('--destination', default=DEFAULT_DEST, help='New Shared36 evidence folder only')
    parser.add_argument('--preflight-only', action='store_true', help='Read originals and report; write nothing')
    parser.add_argument('--all-selected-native-jobs-closed', action='store_true',
                        help='Integration attestation: all selected original processes have actually closed')
    args = parser.parse_args()
    config_rel = relative(args.jobs)
    config_raw = read_original(config_rel)
    config = json_value(config_raw)
    require(type(config) is dict and config.get('schema_version') == 1, 'Selection schema_version 1 required')
    specs = config.get('runs')
    require(type(specs) is list and 0 < len(specs) <= 64, 'Explicit 1..64 selected jobs required')
    require(all(type(spec) is dict and type(spec.get('id')) is str for spec in specs), 'Malformed selected job')
    require(len({spec['id'] for spec in specs}) == len(specs), 'Duplicate selected job')
    destination_rel = relative(args.destination)
    require(re.fullmatch(r'docs/development/evidence/shared36-[a-z0-9-]+', destination_rel),
            'Only a new Shared36 evidence folder may be created; old archives cannot be targets')
    require(args.preflight_only or args.all_selected_native_jobs_closed,
            'Archive execution requires actual all-selected-native-jobs-closed attestation')
    documents = config.get('publication_documents', [])
    require(type(documents) is list and all(type(value) is str for value in documents),
            'Publication documents must be existing relative paths')
    scopes = [preflight_run(spec) for spec in specs]
    report = build(scopes, config_rel, config_raw, destination_rel, documents, not args.preflight_only)
    print(json.dumps(report, indent=2, allow_nan=False))


if __name__ == '__main__':
    main()
