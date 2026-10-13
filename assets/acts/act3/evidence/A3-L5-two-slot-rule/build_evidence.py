from pathlib import Path
import hashlib, json, shutil, gzip, re, datetime

TASK_ROOT = Path.cwd().resolve()
OUT = TASK_ROOT / '.cinder/a3-l5-max2-evidence-draft'
EVIDENCE = TASK_ROOT / 'assets/acts/act3/evidence'
PRIOR_NAMES = ['A3-L5-first-capture-rule', 'A3-L5-public-clock-join', 'A3-L5-native-portraits']
PINNED = ['451eab12e4532df84e90d9cde5320fc1ee3824d6f89756f805a1ddf6895ee1ac', '0f01194ae5bbbf4abbbfe16deee790a4d224fffdd7295fec7b75a4e5d0e4b059', 'e1f8bc55065b4006e7249a252e75420ea12814c6cdb775b6bc08993c2b61a165']
RUNS = [('crystalman-max2-import-native','closed_clean_import'), ('crystalman-max2-first-native','closed_fixture_accounting_failure_and_recursion_diagnostics'), ('crystalman-max2-accounting-corrected-native','closed_actual_wide_current_view_rejection'), ('crystalman-max2-rearmed-route-native','closed_clean_max2_focused_cases'), ('crystalman-max2-default-one-regression-native','closed_clean_ordinary_only_default_one_regression')]
CUSTODY = ['a3-l5-max2-publication','a3-l5-max2-native-accounting-fix','a3-l5-max2-rearmed-route-fix']
AUDITS = ['a3-l5-focus-pause-review','a3-l5-max2-event-accounting-review']
CACHE = {}

def digest(p):
    p = p.resolve()
    key = (str(p), p.stat().st_size, p.stat().st_mtime_ns)
    if key not in CACHE:
        h = hashlib.sha256()
        with p.open('rb') as f:
            for block in iter(lambda:f.read(1024*1024), b''): h.update(block)
        CACHE[key] = h.hexdigest()
    return CACHE[key]

def within(p, root):
    p = p.resolve()
    assert p.is_relative_to(root.resolve()), ('path escape',p,root)
    return p

def record(p, rel=None):
    return {'path': rel if rel is not None else p.relative_to(OUT).as_posix(), 'bytes':p.stat().st_size,'sha256':digest(p)}

def copy_exact(src, dest):
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(src,dest)
    assert src.stat().st_size == dest.stat().st_size and digest(src)==digest(dest)
    return record(dest)

def write_json(p, value):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n')

OUT.mkdir(parents=True,exist_ok=True)
(OUT/'.gdignore').write_bytes(b'')
prior_checks=[]; prior_catalogue={}; previous_source_refs=0
for name,pin in zip(PRIOR_NAMES,PINNED):
    root=EVIDENCE/name; index=root/'index.json'
    assert digest(index)==pin, ('prior index pin',name)
    data=json.loads(index.read_text())
    for a in data['artifacts']:
        p=within(root/a['path'],EVIDENCE)
        assert p.is_file() and p.stat().st_size==a['bytes'] and digest(p)==a['sha256'], ('prior artifact',name,a['path'])
        if a['path'].startswith('source-blobs/'):
            prior_catalogue.setdefault(a['sha256'], {'packet_path':'../'+name+'/'+a['path'],'bytes':a['bytes'],'sha256':a['sha256'],'packet_index_path':'../'+name+'/index.json','packet_index_sha256':pin})
    maps=[]
    for p in root.rglob('source-map.json'):
        m=json.loads(p.read_text()); refs=m['sources']
        assert m.get('source_count',len(refs))==len(refs)
        for a in refs:
            q=within(root/a['packet_path'],EVIDENCE)
            assert q.is_file() and q.stat().st_size==a['bytes'] and digest(q)==a['sha256'], ('prior referent',p,a['packet_path'])
            physical=q.relative_to(EVIDENCE).as_posix()
            owner=physical.split('/')[0]
            owner_index=EVIDENCE/owner/'index.json'
            prior_catalogue.setdefault(a['sha256'], {'packet_path':'../'+physical,'bytes':a['bytes'],'sha256':a['sha256'],'packet_index_path':'../'+owner+'/index.json','packet_index_sha256':digest(owner_index)})
        previous_source_refs+=len(refs); maps.append({'path':p.relative_to(root).as_posix(),'source_count':len(refs),'sha256':digest(p)})
    for a in data.get('prior_packet_indices',[]):
        q=within(root/a['path'],EVIDENCE); assert digest(q)==a['sha256']
    prior_checks.append({'path':'../'+name+'/index.json','sha256':pin,'artifact_count_verified':len(data['artifacts']),'source_maps_verified':maps})
print('Verified prior packets and all declared artifacts/referents:',len(prior_checks),previous_source_refs,flush=True)

source_catalogue=dict(prior_catalogue); local_blobs={}; run_records=[]; all_sources=0; external_count=0
for name,classification in RUNS:
    src=TASK_ROOT/'.cinder'/name; target=OUT/'runs'/name
    result=json.loads((src/'result.json').read_text()); manifest=json.loads((src/'source-freeze.json').read_text())
    assert result.get('closed_at') and result['original_source_changes']==[]
    assert result['frozen_inputs']==len(manifest['sources'])
    for filename in ['result.json','command.json','source-freeze.json']: copy_exact(src/filename,target/filename)
    mapping=[]
    for logical,sha in manifest['sources'].items():
        frozen=within(src/'sources'/logical,src/'sources')
        assert frozen.is_file() and digest(frozen)==sha, ('frozen original',name,logical)
        if sha not in source_catalogue:
            rel='source-blobs/'+sha+'/'+Path(logical).name
            copy_exact(frozen,OUT/rel)
            source_catalogue[sha]={'packet_path':rel,'bytes':frozen.stat().st_size,'sha256':sha}
            local_blobs[sha]=source_catalogue[sha]
        blob=source_catalogue[sha]
        assert frozen.stat().st_size==blob['bytes']
        ref={'original_logical_path':logical,'original_frozen_path':'.cinder/'+name+'/sources/'+logical,**blob}
        mapping.append(ref); all_sources+=1
        external_count+=int(blob['packet_path'].startswith('../'))
    write_json(target/'source-map.json',{'schema_version':1,'source_count':len(mapping),'resolution':'packet_path relative to packet root; external sibling refs pinned by packet_index_sha256','sources':mapping})
    raw=src/'native.log'; raw_sha=digest(raw)
    assert raw_sha==result['raw_log_sha256']
    if name=='crystalman-max2-first-native':
        assert raw.stat().st_size==252624484
        gz=target/'native.log.gz'
        with raw.open('rb') as inp, gz.open('wb') as out:
            with gzip.GzipFile(filename='',mode='wb',compresslevel=6,fileobj=out,mtime=0) as z:
                shutil.copyfileobj(inp,z,length=1024*1024)
        h=hashlib.sha256(); size=0
        with gzip.open(gz,'rb') as f:
            for chunk in iter(lambda:f.read(1024*1024),b''): size+=len(chunk);h.update(chunk)
        assert size==raw.stat().st_size and h.hexdigest()==raw_sha
        log={'portable_path':gz.relative_to(OUT).as_posix(),'encoding':'gzip','compressed_bytes':gz.stat().st_size,'compressed_sha256':digest(gz),'decompressed_original_bytes':size,'decompressed_original_sha256':h.hexdigest(),'original_path':'.cinder/'+name+'/native.log','original_preserved_unchanged':True,'decompression_verified':True}
        write_json(target/'native-log-encoding.json',log)
    else:
        copy_exact(raw,target/'native.log')
        log={'portable_path':(target/'native.log').relative_to(OUT).as_posix(),'encoding':'identity','original_bytes':raw.stat().st_size,'original_sha256':raw_sha}
    footers=[]; passes=0; failures=[]; diagnostics=0; recursion=0
    with raw.open(errors='replace') as f:
        for lineno,line in enumerate(f,1):
            if line.startswith('PASS:'): passes+=1
            if 'FAIL:' in line: failures.append({'line':lineno,'text':line.rstrip()[:2000]})
            if line.startswith('ERROR:') or line.startswith('SCRIPT ERROR:'): diagnostics+=1
            if 'ERROR: Max recursion reached' in line: recursion+=1
            if 'Crystalman two-slot rule draft:' in line or 'Crystalman first one-slot rule room:' in line: footers.append(line.rstrip())
    assert footers==result.get('footers',footers)
    if classification.startswith('closed_clean'): assert result['exit_code']==0 and not result.get('diagnostics',[]) and diagnostics==0
    parsed=re.search(r'(\d+) checks; failures: (\d+); actual post-actor ticks: (\d+)',footers[-1]) if footers else None
    run_records.append({'name':name,'classification':classification,'original_directory':'.cinder/'+name,'result_path':str((target/'result.json').relative_to(OUT)),'command_path':str((target/'command.json').relative_to(OUT)),'manifest_path':str((target/'source-freeze.json').relative_to(OUT)),'source_map_path':str((target/'source-map.json').relative_to(OUT)),'exit_code':result['exit_code'],'closed_at_original':result['closed_at'],'command':result['command'],'source_count':len(mapping),'baseline':manifest['baseline'],'api_revision':manifest['api_revision'],'owned_head_original':manifest['owned_head'],'driver_sha256':manifest['sources'].get('scripts/dev/dev.py'),'runtime_sha256':manifest['sources'].get('scripts/acts/act3/crystalman_rule_room.gd'),'smoke_sha256':manifest['sources'].get('tests/acts/act3/crystalman_rule_room_smoke.gd'),'two_slot_smoke_sha256':manifest['sources'].get('tests/acts/act3/crystalman_two_slot_rule_room_smoke.gd'),'footers':footers,'checks':int(parsed[1]) if parsed else None,'failures':int(parsed[2]) if parsed else None,'actual_post_actor_ticks':int(parsed[3]) if parsed else None,'pass_lines':passes,'error_diagnostic_lines':diagnostics,'max_recursion_diagnostic_lines':recursion,'failure_lines':failures,'original_source_changes':[],'log':log})
    print('Verified/copied CLOSED',name,len(mapping),flush=True)

for name in CUSTODY:
    src=TASK_ROOT/'.cinder'/name
    for p in src.rglob('*'):
        if p.is_file(): copy_exact(p,OUT/'custody'/name/p.relative_to(src))
for name in AUDITS:
    src=TASK_ROOT/'.cinder'/name
    for p in src.rglob('*'):
        if p.is_file(): copy_exact(p,OUT/'audits'/name/p.relative_to(src))

pub=TASK_ROOT/'.cinder/a3-l5-max2-publication'
c=json.loads((pub/'custody.json').read_text())
for a in c['files']:
    for when in ['before','after']:
        sha=a[when+'_sha256']
        p=pub/when/a['path']
        if sha is None: assert not p.exists()
        else: assert digest(p)==sha
for name in CUSTODY[1:]:
    src=TASK_ROOT/'.cinder'/name; r=json.loads((src/'receipt.json').read_text())
    assert digest(src/'before.gd.txt')==r['before_sha256'] and digest(src/'after.gd.txt')==r['after_sha256']
prior_uids=json.loads((pub/'prior-uids.json').read_text())
imp=json.loads((TASK_ROOT/'.cinder/crystalman-max2-import-native/result.json').read_text())
assert len(prior_uids)==450 and imp['prior_uid_count']==450 and imp['prior_uid_changes']==[]
assert all(imp['all_current_uid_sha256'].get(k)==v for k,v in prior_uids.items())
assert imp['current_uid_count']==451 and imp['duplicate_uid_values']==[] and len(imp['new_uid_paths'])==1
new_uid=imp['new_uid_paths'][0]
frozen_uid=TASK_ROOT/'.cinder/crystalman-max2-first-native/sources'/new_uid
assert digest(frozen_uid)==imp['all_current_uid_sha256'][new_uid]
write_json(OUT/'verification.json',{'status':'ALL_CLOSED_ORIGINALS_AND_PORTABLE_REFERENTS_VERIFIED','only_closed_runs':True,'active_source_read':False,'prior_packet_checks':prior_checks,'prior_packet_source_referents_verified':previous_source_refs,'new_run_source_references_verified':all_sources,'external_same_byte_source_references':external_count,'new_unique_source_blobs':len(local_blobs),'prior_uids_verified_exact':450,'genuine_new_uid':{'path':new_uid,'sha256':digest(frozen_uid)},'current_unique_uids':451,'custody_before_after_verified':True,'gzip_decompression_verified':True})

readme='''# A3-L5 max2 focused native evidence draft

This ignored packet is reviewable evidence for Root publication. It preserves five explicitly CLOSED native originals and their exact source freezes. It is not complete Crystalman level acceptance.

| Closed run | Result | Actual ticks | Frozen sources |
| --- | --- | --- | --- |
| max2 import | 0 clean; prior 450 UIDs exact, one genuine new UID, 451 unique | n/a | 539 |
| first max2 | 46 checks /1 failure; 256 recursion diagnostics plus final accounting failure retained | 580 | 538 |
| accounting corrected | 70 checks /1 legitimate whole current-view rejection retained | 1030 | 538 |
| rearmed compact route | 104 checks /0 failures, clean | 1356 | 538 |
| affected default-one ordinary regression | 32 checks /0 failures, clean; invalid branch skipped by original selector | 484 | 535 |

The first failure is the fixture's raw dispatch>=scheduled predicate, incompatible with the existing canonical Cursor derived-deadline precision contract. Its diagnostic printed a live actor Object recursively. The saved accounting-fix receipt preserves the original source and its exact correction: canonical public cursor validation and exact event/opportunity-prefix joins, early-dispatch/altered-schedule negative checks, and diagnostic actor instance ID. No shared timing/proof/deadline/tolerance changed. The corrected fixture then reached a legitimate combined footprint/source/landing union too wide for the actual current fixed-width portrait. The saved route-fix receipt preserves that result and records only real routed movement followed by compact voluntary recordings. No pose, camera, floor, HP, gear or clock rewrite was used.

The clean 104/0 scope includes both actual completed dash+primary recordings, whole admission/fresh lock, both response escapes and their original deadlines, actual primary full recovery, exact FIFO/native event accounting, completed projected leaf Pause and consumed Resume, invalid second-slot whole-unit rejection and visible rearm, later once-only/nonrecursive behavior and normal cleanup. Original source comments saying DRAFT/UNEXECUTED remain archived byte-exact; these closed run results qualify only their actual tested scope.

All other logs are copied exact. The 252,624,484-byte first log is represented portably by native.log.gz: native-log-encoding.json discloses original and compressed sizes/hashes and verified decompression. The raw original is retained unchanged outside this packet. No log was truncated, edited or deleted. Every source-map record preserves logical path and original freeze hash. Identical source bytes are referenced from pinned earlier first-capture/public-clock/native-portrait packet indices or a single new local hash blob. For a published sibling evidence folder, resolve packet_path relative to the packet root. For this ignored draft, external ../A3-L5-* paths resolve to the existing owned assets/acts/act3/evidence siblings; verification.json records their exact index pins and full artifact/referent checks. Earlier images/results remain their original one-slot source evidence, not max2 graphical credit.

Saved publication before/after originals, live equipment/ability query originals, both fixture-fix custody directories, and completed focus/event/current-publication audits are included unchanged. Source freezes grant no separate gameplay acceptance. The saved queries record 36 canonical equipment items/revision0/zero claims or duplicates and 20 abilities/zero introduction uses; this packet creates no allocation.

Remaining scope: no max2 graphical images, whole-parent codec/Save/Continue/Retry, campaign phase progression/registration/transitions, full layout/production art/preview, broad loadout coverage, full playthrough or full A3-L5 acceptance. Prior 70/0 four native portraits belong to their exact earlier one-slot source pins; their focus recovery was warning-phase, not proven in-flight-lock coverage. No mobile/export/release work was performed. Root owns publication and commits.
'''
(OUT/'README.md').write_text(readme)
artifacts=[record(p) for p in sorted(OUT.rglob('*')) if p.is_file() and p.name not in ['index.json','READY.json']]
index={'schema_version':1,'level_id':'A3-L5','created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'Max2 captured-action prototype focused native originals, retained failures and directly affected ordinary-only default-one regression; no full-level/graphical/whole-parent acceptance.','baseline':'8cb1da79ba000d758fe677054782e23f48cb6dfd','api_revision':'campaign-shared-53','prior_packet_indices':prior_checks,'runs':run_records,'source_reference_count':all_sources,'external_same_byte_source_references':external_count,'new_unique_source_blobs':len(local_blobs),'artifact_count_excluding_index_and_READY':len(artifacts),'artifacts':artifacts,'limitations':['no max2 graphical acceptance','no whole-parent codec/Save/Continue/Retry','no production art/layout/full preview','no campaign registration or phase progression','no broad loadouts/full playthrough/full A3-L5 acceptance']}
write_json(OUT/'index.json',index)

# Recheck the portable draft as an independent read of the emitted records.
for a in index['artifacts']:
    p=within(OUT/a['path'],OUT); assert p.stat().st_size==a['bytes'] and digest(p)==a['sha256']
for run in index['runs']:
    m=json.loads((OUT/run['source_map_path']).read_text())
    for a in m['sources']:
        p=EVIDENCE/a['packet_path'][3:] if a['packet_path'].startswith('../') else OUT/a['packet_path']
        assert p.stat().st_size==a['bytes'] and digest(p)==a['sha256']
        if 'packet_index_path' in a: assert digest(EVIDENCE/a['packet_index_path'][3:])==a['packet_index_sha256']
first=index['runs'][1]['log']
original=TASK_ROOT/first['original_path'];assert original.stat().st_size==first['decompressed_original_bytes'] and digest(original)==first['decompressed_original_sha256']
ready={'status':'READY_FOR_ROOT_REVIEW_AND_PUBLICATION','stage_root':str(OUT),'index_sha256':digest(OUT/'index.json'),'index_bytes':(OUT/'index.json').stat().st_size,'artifact_count_excluding_index_and_READY':len(artifacts),'physical_file_count_including_index_and_READY':len(artifacts)+2,'source_reference_count':all_sources,'new_unique_source_blobs':len(local_blobs),'external_same_byte_source_references':external_count,'all_referents_and_decompression_verified':True,'all_five_runs_explicitly_closed':True,'default_one_closed_included':True,'active_source_read':False,'owned_edits':False,'engine_or_UID_or_allocation':False,'first_raw_log_preserved':True,'first_log_encoding':first,'scope':'focused portable evidence only; no full A3-L5/max2 graphical/whole-parent acceptance'}
write_json(OUT/'READY.json.tmp',ready);(OUT/'READY.json.tmp').replace(OUT/'READY.json')
print(json.dumps(ready,indent=2),flush=True)
