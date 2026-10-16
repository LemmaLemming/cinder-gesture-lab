#!/usr/bin/env python3
"""Source-only, explicitly selected L1 amendment evidence packager.

Execute later only at Root's CLOSED boundary. This script was not run during
preparation. Writes ONLY assets/acts/act3/evidence/A3-L1-arrangement-native.

Example (use actual finalized names, not this illustrative list):
  python3 /private/tmp/package_l1_arrangement_evidence.py --closed-boundary \
    --run original-challenge-producer-01 --run original-challenge-producer-02 \
    --run candidate-parse-01 --run candidate-pure-01 --run legacy-reader-01 \
    --run current-persistence-01 \
    --capture captures/act3/twin-suns-arrangement/arrangement-current-ACTUAL \
    --preserve-dir failed-original-producer-02

--partial-run NAME=REASON is only for an explicitly closed incomplete archive
without a result. It grants no native success. --run-note NAME=TEXT records a
reviewer's narrow scope/limitation, not an inferred global acceptance. No glob
or automatic run/capture discovery, native command, source edit, Git write,
image editing or cleanup/deletion is performed. Existing evidence is never
overwritten; a partial failed pack is preserved for Root's inspection.
"""
from pathlib import Path, PurePosixPath
import argparse
import datetime
import hashlib
import json
import os
import re
import stat
import subprocess

ROOT = Path('/Users/howardchen/.codex/worktrees/campaign-act3/video game idea')
RUN_ROOT = ROOT / '.cinder/l1-arrangement-runs'
CAPTURE_ROOT = ROOT / 'captures/act3/twin-suns-arrangement'
DEST = ROOT / 'assets/acts/act3/evidence/A3-L1-arrangement-native'
REQUIRED = ('command.json', 'sources.json', 'result.json', 'native.log')
DIAGNOSTIC = re.compile(r'^\s*(?:SCRIPT ERROR:|ERROR:|WARNING:|Parse Error:|ERROR at |WARNING at )')
SHA = re.compile(r'^[0-9a-f]{64}$')
NAME = re.compile(r'^[a-z0-9][a-z0-9-]*$')
COMMIT = re.compile(r'^[0-9a-f]{40}$')


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_frozen(path):
    require(path.is_file() and not path.is_symlink(), 'Regular original file required: '+str(path))
    before = path.stat()
    data = path.read_bytes()
    after = path.stat()
    require((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) ==
            (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns),
            'Input changed while reading: '+str(path))
    return data, stat.S_IMODE(after.st_mode)


def inside(path, base):
    require(not path.is_symlink() and path.resolve().is_relative_to(base.resolve()),
            'Input escapes its exact owned scope: '+str(path))
    return path


def logical_path(value):
    p = PurePosixPath(value)
    require(not p.is_absolute() and '..' not in p.parts and str(p) == value,
            'Unsafe logical source path: '+str(value))
    return value


def output_path(relative):
    logical_path(relative)
    path = DEST / relative
    cursor = ROOT
    for part in path.relative_to(ROOT).parts:
        cursor = cursor / part
        require(not cursor.is_symlink(), 'Output symlink/ancestor refused: '+str(cursor))
        require(cursor.resolve().is_relative_to(ROOT.resolve()), 'Output escaped registered checkout')
        if cursor != path and cursor.exists():
            require(cursor.is_dir(), 'Output ancestor is not a directory: '+str(cursor))
    return path


def closed_observations(manifest, result, name):
    require(isinstance(manifest,dict) and isinstance(result,dict), 'Closed native objects required: '+name)
    require(isinstance(manifest.get('head'),str) and COMMIT.fullmatch(manifest['head']) and
            isinstance(manifest.get('shared_api'),str) and manifest['shared_api'] and
            isinstance(manifest.get('started_at'),str) and manifest['started_at'] and
            isinstance(manifest.get('scope'),str) and manifest['scope'] and
            isinstance(manifest.get('selected_sources'),dict) and manifest['selected_sources'] and
            isinstance(manifest.get('missing_before'),list) and
            all(isinstance(v,str) for v in manifest['missing_before']),
            'Missing/invalid original scoped source custody: '+name)
    require(isinstance(result.get('closed_at'),str) and result['closed_at'] and
            isinstance(result.get('actual_exit_code'),int) and not isinstance(result['actual_exit_code'],bool) and
            isinstance(result.get('head_after'),str) and COMMIT.fullmatch(result['head_after']) and
            isinstance(result.get('native_log_sha256'),str) and SHA.fullmatch(result['native_log_sha256']) and
            isinstance(result.get('allowed_new_uid_observations'),dict),
            'Missing/invalid original closed native custody: '+name)
    for key in ('diagnostics','selected_source_changes_during_run','footers'):
        require(isinstance(result.get(key),list) and all(isinstance(v,str) for v in result[key]),
                'Missing/invalid original '+key+': '+name)


def pairs(values):
    out = {}
    for value in values:
        name, separator, text = value.partition('=')
        require(separator and NAME.fullmatch(name) and text.strip() and name not in out,
                'Expected unique NAME=TEXT: '+value)
        out[name] = text
    return out


def git(*args):
    return subprocess.check_output(['git','--no-optional-locks',*args],cwd=ROOT)


class Pack:
    def __init__(self):
        self.files = {}
        self.inputs = {}
        self.blobs = {}

    def original(self, path):
        data, mode = read_frozen(path)
        observed = {'sha256':digest(data),'bytes':len(data),'mode':format(mode,'04o')}
        previous = self.inputs.get(str(path))
        require(previous is None or previous == observed, 'Input drift during packaging: '+str(path))
        self.inputs[str(path)] = observed
        return data, mode

    def artifact(self, relative, data, mode=0o644, origin=None):
        logical_path(relative)
        output = output_path(relative)
        output.parent.mkdir(parents=True,exist_ok=True)
        output_path(relative)
        if output.exists():
            old, old_mode = read_frozen(output)
            require(old == data and old_mode == mode, 'Existing different evidence refused: '+str(output))
        else:
            with output.open('xb') as stream:
                stream.write(data)
                stream.flush()
                os.fsync(stream.fileno())
            output.chmod(mode)
        row = self.files.setdefault(relative,{'sha256':digest(data),'bytes':len(data),
                                              'mode':format(mode,'04o'),'original_absolute_paths':[]})
        require(row['sha256'] == digest(data) and row['bytes'] == len(data), 'Artifact alias collision')
        if origin is not None and str(origin) not in row['original_absolute_paths']:
            row['original_absolute_paths'].append(str(origin))
        return relative

    def copy(self, path, relative):
        data, mode = self.original(path)
        self.artifact(relative,data,mode,path)
        return self.files[relative]

    def blob(self, path, expected):
        require(SHA.fullmatch(expected), 'Malformed source digest')
        data, _mode = self.original(path)
        require(digest(data) == expected, 'Frozen source blob mismatches recorded hash: '+str(path))
        target = 'source-blobs/'+expected+'.bin'
        self.artifact(target,data,0o644,path)
        self.blobs[expected] = target
        return target

    def directory(self, original, destination):
        rows = {}
        for path in sorted(original.rglob('*')):
            require(not path.is_symlink(), 'Symlink inside explicit evidence folder: '+str(path))
            if not path.is_file():
                continue
            suffix = path.relative_to(original).as_posix()
            rows[suffix] = self.copy(path,destination+'/'+suffix)
        require(rows, 'Explicit evidence folder is empty: '+str(original))
        return rows

    def verify_inputs(self):
        for name, expected in self.inputs.items():
            data, mode = read_frozen(Path(name))
            require({'sha256':digest(data),'bytes':len(data),'mode':format(mode,'04o')} == expected,
                    'Original changed before final index: '+name)


def run_record(pack, name, partial_reason, note):
    require(NAME.fullmatch(name), 'Bad exact run name: '+name)
    source = inside(RUN_ROOT/name,RUN_ROOT)
    require(source.is_dir(), 'Named run folder missing: '+name)
    result_path = source/'result.json'
    if partial_reason is None:
        require(all((source/f).is_file() for f in REQUIRED), 'Run is not finalized; no result/native claim: '+name)
    else:
        require(not result_path.exists(), 'Closed runs with a result must use --run: '+name)
    artifacts = {}
    parsed = {}
    for path in sorted(source.iterdir()):
        require(not path.is_symlink(), 'Run symlink refused: '+str(path))
        if not path.is_file():
            continue
        require(path.suffix in ('.json','.log','.txt'), 'Unreviewed run-root file: '+str(path))
        relative = 'runs/'+name+'/'+path.name
        artifacts[path.name] = pack.copy(path,relative)
        if path.name in ('command.json','sources.json','result.json'):
            parsed[path.name] = json.loads(path.read_text())
    manifest = parsed.get('sources.json',{})
    result = parsed.get('result.json')
    if partial_reason is None:
        closed_observations(manifest,result,name)
    require(isinstance(manifest,dict), 'Run source manifest must be an object')
    mapping = {}
    selected = manifest.get('selected_sources',{})
    require(isinstance(selected,dict), 'selected_sources must be the original scoped mapping')
    for logical, expected in sorted(selected.items()):
        logical_path(logical)
        storage = inside(source/'source-blobs'/(expected+'.bin'),source)
        mapping[logical] = {'sha256':expected,'storage':pack.blob(storage,expected),
                            'original_frozen_blob_absolute_path':str(storage)}
    post_uids = {}
    if result is not None:
        require(isinstance(result,dict) and isinstance(result.get('closed_at'),str) and
                isinstance(result.get('actual_exit_code'),int) and not isinstance(result['actual_exit_code'],bool),
                'Malformed closed result: '+name)
        for logical, expected in result.get('allowed_new_uid_observations',{}).items():
            logical_path(logical)
            require(logical.endswith('.uid') and logical in manifest.get('missing_before',[]),
                    'Unexpected post-run UID observation: '+logical)
            # This is explicitly POST-run, not an invented pre-run freeze blob.
            post_uids[logical] = {'sha256':expected,'storage':pack.blob(inside(ROOT/logical,ROOT),expected),
                                  'provenance':'existing bytes matched against original result post-run UID observation'}
    log = source/'native.log'
    text = log.read_text(errors='replace') if log.exists() else ''
    raw_diagnostics = [{'line':i,'text':line} for i,line in enumerate(text.splitlines(),1) if DIAGNOSTIC.match(line)]
    summaries = [line for line in text.splitlines() if line.startswith(('Twin Suns arrangement','Twin Suns original producer:'))]
    counter_rows = []
    for line in summaries:
        counter = re.match(r'^Twin Suns arrangement(?: original producer)?: (\d+) checks/(\d+) failures;',line)
        if counter:
            complete = re.search(r'complete=(true|false)',line)
            native = re.search(r'observations=(\d+)',line)
            counter_rows.append({'checks':int(counter[1]),'failures':int(counter[2]),
                                 'scope_complete_as_printed':complete[1] if complete else None,
                                 'producer_observations_as_printed':int(native[1]) if native else None,
                                 'scope_note':'Producer observation count is not component ticks. Compare cases separately print202/202/215 native ticks; counter checks are guarded case/setup/difference/cleanup assertions, not per-tick assertion counts.',
                                 'original_native_footer':line})
    assertion_rows = [re.match(r'^(PASS|ERROR: FAIL): ',line) for line in text.splitlines()]
    assertion_rows = [row for row in assertion_rows if row is not None]
    for counter in counter_rows:
        require(counter['checks']==len(assertion_rows) and counter['failures']==sum(row[1]=='ERROR: FAIL' for row in assertion_rows),'Actual assertion rows/footer mismatch: '+name)
    if result is not None:
        require(result.get('native_log_sha256') == artifacts['native.log']['sha256'], 'Native log/result mismatch: '+name)
        changes = result.get('selected_source_changes_during_run',[])
        head_drift = result.get('head_after') != manifest.get('head')
        diagnostics = result.get('diagnostics',[])
        require(isinstance(changes,list) and isinstance(diagnostics,list), 'Malformed closure observations')
        code = result['actual_exit_code']
        if code != 0:
            classification = 'closed-nonzero-exit; retain exact partial/failed scope'
        elif diagnostics or raw_diagnostics or changes or head_drift:
            classification = 'closed-zero-exit-with-diagnostics-or-custody-drift; no clean-pass claim'
        elif summaries:
            classification = 'closed-clean-zero-exit; scope limited to exact native footer and reviewed note'
        else:
            classification = 'closed-clean-zero-exit-without-gameplay-footer; no gameplay claim'
    else:
        changes, head_drift, diagnostics, code = None, None, None, None
        classification = 'root-attested-closed-incomplete-archive; no completed native result'
    return {'original_absolute_directory':str(source),'artifacts':artifacts,
            'classification':classification,'explicit_review_note':note,
            'partial_closure_attestation':partial_reason,'actual_exit_code_as_recorded':code,
            'started_head':manifest.get('head'),'head_after':result.get('head_after') if result else None,
            'shared_api_as_recorded':manifest.get('shared_api'),'source_scope_as_recorded':manifest.get('scope'),
            'selected_source_mapping':mapping,'post_run_uid_observations':post_uids,
            'recorded_source_drift':changes,'recorded_head_drift':head_drift,
            'recorded_diagnostics':diagnostics,'native_log_diagnostic_lines':raw_diagnostics,
            'native_summary_lines':summaries,'native_footer_counters':counter_rows,
            'observed_assertion_row_count':len(assertion_rows),
            'observed_failed_assertion_row_count':sum(row[1]=='ERROR: FAIL' for row in assertion_rows),
            'recorded_footers_unmodified_in_result':True,
            'command':parsed.get('command.json')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--closed-boundary',action='store_true',required=True,
                        help='Root attests every explicitly selected run/capture is closed and immutable')
    parser.add_argument('--run',action='append',default=[],metavar='EXACT-CLOSED-NAME')
    parser.add_argument('--partial-run',action='append',default=[],metavar='EXACT-NAME=CLOSURE-REASON')
    parser.add_argument('--run-note',action='append',default=[],metavar='EXACT-NAME=NARROW-REVIEWED-SCOPE')
    parser.add_argument('--capture',action='append',default=[],metavar='captures/act3/twin-suns-arrangement/arrangement-ACTUAL')
    parser.add_argument('--preserve-dir',action='append',default=[],choices=['failed-original-producer-02'])
    parser.add_argument('--legacy-fixture',action='store_true',help='Also copy the exact original eighteen-successful-plus-eleven-failed-partial-file fixture folder')
    args = parser.parse_args()
    partial = pairs(args.partial_run)
    notes = pairs(args.run_note)
    names = args.run+list(partial)
    require(names and len(names)==len(set(names)), 'Explicit unique run list required; no automatic discovery')
    require(set(notes).issubset(names), 'Review notes must name selected runs only')
    require(len(args.capture)==len(set(args.capture)) and len(args.preserve_dir)==len(set(args.preserve_dir)), 'Duplicate folder selection')
    require(git('rev-parse','--show-toplevel').decode().strip()==str(ROOT), 'Wrong registered checkout')
    require(git('branch','--show-current').decode().strip()=='codex/campaign-act3', 'Wrong branch')
    index_path = output_path('index.json')
    hash_path = output_path('index.sha256')
    require(not index_path.exists() and not hash_path.exists(), 'Prior completed index exists; never overwrite')
    if DEST.exists():
        permitted = set(args.preserve_dir)|{'.gdignore'}
        require({p.name for p in DEST.iterdir()}.issubset(permitted), 'Unlisted existing evidence; explicitly preserve/review it first')
    for path in args.capture:
        logical_path(path)
        capture = ROOT/path
        require(capture.parent == CAPTURE_ROOT and capture.name.startswith(('current-held-','crossing-portrait-')) and capture.is_dir(),
                'One exact actual arrangement capture directory required: '+path)
        inside(capture,CAPTURE_ROOT)
    pack = Pack()
    rows = {}
    for name in names:
        rows[name] = run_record(pack,name,partial.get(name),notes.get(name,''))
    captures = {}
    for path in args.capture:
        source = ROOT/path
        captures[path] = {'original_absolute_directory':str(source),
                          'files':pack.directory(source,'captures/'+source.name),
                          'scope':'original native files copied unchanged; existence alone grants no visual inspection/acceptance'}
    retained = {}
    for name in args.preserve_dir:
        source = inside(DEST/name,DEST)
        require(source.is_dir(), 'Explicit prior partial is missing: '+name)
        retained[name] = {'files':pack.directory(source,name),
                          'scope':'original failed-producer partial retained; not a completed producer/held fixture'}
    if args.legacy_fixture:
        source = inside(ROOT/'tests/acts/act3/fixtures/a3_l1_arrangement_legacy',ROOT)
        retained['original-legacy-fixture'] = {'files':pack.directory(source,'original-legacy-fixture'),
                                             'scope':'actual original fixture bytes; its original manifest/result/source pins govern provenance'}
    # Exact reviewed host observations, validators and original authorization.
    for relative in ['.cinder/l1-arrangement-full-canonical-gate.json','.cinder/l1-component-expectation-review.json','.cinder/l1-arrangement-portrait-review.json','.cinder/act3-shared68-adoption-after.json']:
        pack.copy(inside(ROOT/relative,ROOT),'host/'+Path(relative).name)
    for name in ['ability','equipment','numerical']:
        source=inside(ROOT/'.cinder/l1-arrangement-validators'/(name+'.json'),ROOT)
        require(json.loads(source.read_text())['exit_code']==0,'Required canonical validator did not pass: '+name)
        pack.copy(source,'validators/'+source.name)
    canonical=Path('/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/agent-chat/cinder-campaign')
    for role,name in [('integration','2a823c38-5495-44ba-ac31-db7ee884dff2-RESPONSE.json'),('integration','8dd347ed-af96-4dfd-9290-0f77022c3bb5-RESPONSE.json'),('act3','42fcc68e-c8ae-4bd0-83ca-cf0bed13c507-ACK.json')]:
        pack.copy(canonical/role/'messages'/name,'coordination/'+name)
    proposal=Path('/private/tmp/A3_L1_DIFFICULTY_PROPOSAL.md')
    require(digest(proposal.read_bytes())=='454528f285a234e29effa72e6ea920b6ce68c3fee8882cbc96c1cc162c846dea','Exact approved original proposal required')
    pack.copy(proposal,'coordination/approved-private-proposal.md')
    pack.artifact('.gdignore',b'',origin=None)
    script_data, script_mode = pack.original(Path(__file__).resolve())
    pack.artifact('custody/package_l1_arrangement_evidence.py',script_data,script_mode,Path(__file__).resolve())
    readme = ('# A3-L1 additional arrangement native evidence\n\n'
              'Exact explicitly selected originals only. Original eight-level acceptance remains complete; '
              'this is a separate bounded L1 crossing-depth arrangement amendment. Run exit/diagnostic/head/source observations and '
              'native footers retain their own scope, including failures, partials, import/parse-only and '
              'unexecuted branches. No full-route, global resource/UID census, universal accepted-file closure, '
              'pacing or human balance/readability claim is inferred. Capture pixels remain original; '
              'visual inspection is separate evidence. Component declarations do not grant parent earned '
              'history or Save/Continue credit.\n\n'
              'index.json maps each exact native source digest to a deduplicated unchanged .bin blob. '
              'Raw command.json/sources.json/result.json/native.log and run-root receipts are byte copies. '
              'Existing failed-original-producer-02 originals are retained when explicitly selected. '
              'The file inventory excludes index.json and its detached index.sha256 to avoid circular hashes. '
              'The final printed index digest is the pack identity. No original is rewritten.\n\n'
              'Selected runs:\n\n'+''.join('- '+n+': '+rows[n]['classification']+'\n' for n in names))
    pack.artifact('README.md',readme.encode())
    pack.verify_inputs()
    index = {'schema_version':1,'kind':'a3-l1-additional-arrangement-native-evidence-1',
             'created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
             'packaging_head':git('rev-parse','HEAD').decode().strip(),
             'closed_boundary_explicit_attestation':True,'script_was_run_to_create_this_index':True,
             'source_scope':'explicit L1/direct dependencies captured by each original runner with original Shared67/68 attribution, genuine old fixture and actual native captures; not global closure',
             'no_acceptance_or_new_native_credit_from_packaging':True,
             'runs':rows,'captures':captures,'retained_originals':retained,
             'files':pack.files,'artifact_count_excluding_index_and_detached_hash':len(pack.files),
             'artifact_bytes_excluding_index_and_detached_hash':sum(v['bytes'] for v in pack.files.values())}
    wire = (json.dumps(index,indent=2,sort_keys=True,ensure_ascii=False)+'\n').encode()
    with output_path('index.json').open('xb') as output:
        output.write(wire)
    index_sha = digest(wire)
    detached = (index_sha+'  index.json\n').encode()
    with output_path('index.sha256').open('xb') as output:
        output.write(detached)
    print(json.dumps({'index':str(DEST/'index.json'),'index_sha256':index_sha,
                      'selected_run_count':len(rows),'source_blob_count':len(pack.blobs),
                      'files_including_index_and_hash':len(pack.files)+2,
                      'bytes_including_index_and_hash':sum(v['bytes'] for v in pack.files.values())+len(wire)+len(detached)},sort_keys=True))


if __name__ == '__main__':
    main()
