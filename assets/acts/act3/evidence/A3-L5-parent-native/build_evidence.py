"""Portable original Shared55 Act3 parent custody; no engine or tracked writes."""
from pathlib import Path
import collections
import datetime
import gzip
import hashlib
import json
import re
import shutil

ROOT = Path('/Users/howardchen/.codex/worktrees/campaign-act3/video game idea')
OUT = ROOT / '.cinder/a3-l5-parent-evidence-plan'
EVIDENCE = ROOT / 'assets/acts/act3/evidence'
PRIOR = {
 'A3-L5-first-capture-rule': '451eab12e4532df84e90d9cde5320fc1ee3824d6f89756f805a1ddf6895ee1ac',
 'A3-L5-public-clock-join': '0f01194ae5bbbf4abbbfe16deee790a4d224fffdd7295fec7b75a4e5d0e4b059',
 'A3-L5-native-portraits': 'e1f8bc55065b4006e7249a252e75420ea12814c6cdb775b6bc08993c2b61a165',
 'A3-L5-two-slot-rule': '53be11ab68f72cdee375540e4ff6d459423b565f0d8d0c96924b464df3c7cba9',
 'A3-L5-local-codec': '9880a6fddc2e1a5b53893a5356f6691b83f91a6d2395e0ac568ce2eaa021d2fa',
}
# Explicitly closed originals only. The nested path is deliberately preserved.
RUNS = [
 ('.cinder/crystalman-full-parent-first-import-native','a916c4c4a7c0705288bec68546f786ca0c03dd14ebc50107d30ae891eaf0dd73'),
 ('.cinder/crystalman-parent-initial-first-native','0e570d2b7b2b9e7f97ee3988f4cd96bb73a352c2ae44e945a1d7f4bae743aa80'),
 ('.cinder/crystalman-parent-preview-difficulty-corrected-native','2dfc08c3078d7416410d31f738faa3dfc6fb7af59016c5c09c6544963e4ae336'),
 ('.cinder/crystalman-parent-entry-operands-native','a554c54335adec4b44cbf3f6a29a0b133d5e1922e000765d02c1ebf5fa3e9da7'),
 ('.cinder/crystalman-parent-complete-world-root-corrected-native','7634abcb5e3b2443cfabfb966ea8c1e77033e184b568651362f62c654e8b3228'),
 ('.cinder/crystalman-parent-initial-view-observed-native','5888e189b6fab7a474ddb354c0622051597814c6f52d5a13db3eece6d3b2a406'),
 ('.cinder/crystalman-parent-initial-disposal-corrected-native','614abff7de1cfd62bee4e2c6c0c3e92e48ecf340e7918d248f3838fcb970134b'),
 ('.cinder/crystalman-parent-declared-phase1-first-native','53caf5f3e1c619b781dbef079834ad143b2cdb87901c430cf3d20ad0477fdcc0'),
 ('.cinder/crystalman-parent-declared-phase1-construction-corrected-native','c8bb66a2bdd0d46a20877a5d3494e479c6bfd990ec73e773d064ae150b3f00c0'),
 ('.cinder/.cinder/crystalman-parent-phase1-seed-diagnostic-native','15a49ae30f602bef332bf8845129e9740213d4993a6d72f561359da35ba7b0cf'),
 ('.cinder/crystalman-parent-phase1-identity-corrected-native','ac36cad86cfc17bc94eb09c27eb5dce0c3f7c0d9b3f1397665f7e1859f71fe7c'),
 ('.cinder/crystalman-parent-phase2-entry-native','6e4c7c339ae733840bc13d54dd4a428a7e857a3db8ecd5d0a35db9aab5068e6a'),
 ('.cinder/crystalman-parent-coda-entry-native','3e336f79a0e80b9e502ac00dd31d4dfd9f377a8556920abea7a6d687e4912586'),
 ('.cinder/crystalman-parent-coda-checkpoint-order-native','504cd3d2d5c5ea29941d2f4ce9018cca90119e6ad9441d7e423b41858775bfe0'),
 ('.cinder/crystalman-parent-real-phases-first-native','2d10dd19143a0a7de1c027b98433209a71e5a4d770c7ac01123b58b79f5e2278'),
 ('.cinder/crystalman-parent-real-phases-harness-corrected-native','4318a3f67b39c736ebf7453124017b82da1c6ab34fe1b6f50bdc5104a7b540a7'),
 ('.cinder/crystalman-parent-real-phases-coda-view-native','06dbdba3dd4f9228bcde83b55ad05ac626e6f9ec4fa53337d8a7c3e92f1572f3'),
 ('.cinder/crystalman-parent-real-phases-exit-approach-native','b964a32728f0035c6a913ea985bb5950b7ad8a7cb9f9d05b8cac4960d0f97a5f'),
]
BASELINE = 'f8b984a2a5371cae3f1deef8aa394bb892f28e78'
CACHE = {}

def sha(p):
 p=p.resolve(); st=p.stat(); key=(str(p),st.st_size,st.st_mtime_ns)
 if key not in CACHE:
  h=hashlib.sha256()
  with p.open('rb') as f:
   for b in iter(lambda:f.read(1048576),b''):h.update(b)
  CACHE[key]=h.hexdigest()
 return CACHE[key]

def load(p):return json.loads(p.read_text())
def write(p,value):
 p.parent.mkdir(parents=True,exist_ok=True)
 tmp=p.with_name(p.name+'.tmp');tmp.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n');tmp.replace(p)
def within(p,root):
 p=p.resolve();assert p.is_relative_to(root.resolve()),('path escape',p,root);return p
def copy(src,dest):
 dest.parent.mkdir(parents=True,exist_ok=True)
 if dest.exists():assert dest.stat().st_size==src.stat().st_size and sha(dest)==sha(src),('original would change',dest)
 else:shutil.copy2(src,dest)
 assert dest.stat().st_size==src.stat().st_size and sha(dest)==sha(src)
def record(p):return {'path':p.relative_to(OUT).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)}

assert not (OUT/'READY.json').exists(),'sealed packet is immutable'
OUT.mkdir(parents=True,exist_ok=True);(OUT/'.gdignore').write_bytes(b'')
copy(Path(__file__),OUT/'build_evidence.py')
catalogue={};prior_checks=[];prior_refs=0
for name,pin in PRIOR.items():
 p=EVIDENCE/name;assert sha(p/'index.json')==pin,('prior index',name);index=load(p/'index.json')
 for a in index['artifacts']:
  q=within(p/a['path'],EVIDENCE);assert q.stat().st_size==a['bytes'] and sha(q)==a['sha256'],('prior artifact',name,a['path'])
  if a['path'].startswith('source-blobs/'):
   catalogue.setdefault(a['sha256'],{'packet_path':'../'+name+'/'+a['path'],'sha256':a['sha256'],'bytes':a['bytes'],'packet_index_path':'../'+name+'/index.json','packet_index_sha256':pin})
 maps=[]
 for m in sorted(p.rglob('source-map.json')):
  refs=load(m)['sources'];assert load(m).get('source_count',len(refs))==len(refs)
  for a in refs:
   q=within(p/a['packet_path'],EVIDENCE);assert q.stat().st_size==a['bytes'] and sha(q)==a['sha256']
   physical=q.relative_to(EVIDENCE).as_posix();owner=physical.split('/')[0]
   catalogue.setdefault(a['sha256'],{'packet_path':'../'+physical,'sha256':a['sha256'],'bytes':a['bytes'],'packet_index_path':'../'+owner+'/index.json','packet_index_sha256':sha(EVIDENCE/owner/'index.json')})
  prior_refs+=len(refs);maps.append({'path':m.relative_to(p).as_posix(),'sha256':sha(m),'source_count':len(refs)})
 for a in index.get('prior_packet_indices',[]):assert sha(within(p/a['path'],EVIDENCE))==a['sha256']
 prior_checks.append({'path':'../'+name+'/index.json','sha256':pin,'artifact_count_verified':len(index['artifacts']),'source_maps_verified':maps})

new_blobs=set();all_sources=0;external=0;runs=[];uid_refs=0
for original_dir,raw_pin in RUNS:
 src=ROOT/original_dir;name=src.name;target=OUT/'runs'/name
 result=load(src/'result.json');freeze=load(src/'source-freeze.json');command=load(src/'command.json')
 assert result['closed_at'] and result['original_source_changes']==[]
 assert result['frozen_inputs']==len(freeze['sources'])
 assert freeze['baseline']==BASELINE and freeze['api_revision']=='campaign-shared-55'
 assert ' '.join(command['command'])==result['command']
 assert result['prior_uid_changes']==[] and not result['duplicate_uid_values']
 for f in ['result.json','command.json','source-freeze.json','prior-uids.json']:copy(src/f,target/f)
 prior=load(src/'prior-uids.json');assert len(prior)==result['prior_uid_count']
 for logical,row in prior.items():assert result['all_current_uid_sha256'].get(logical)==row['sha256']
 uid_refs+=len(prior)
 mapping=[]
 for logical,pin in freeze['sources'].items():
  frozen=within(src/'sources'/logical,src/'sources');assert sha(frozen)==pin,('frozen source',original_dir,logical)
  if pin not in catalogue:
   rel='source-blobs/'+pin+'/'+Path(logical).name;copy(frozen,OUT/rel)
   catalogue[pin]={'packet_path':rel,'sha256':pin,'bytes':frozen.stat().st_size};new_blobs.add(pin)
  ref=catalogue[pin];assert frozen.stat().st_size==ref['bytes']
  mapping.append({'original_logical_path':logical,'original_frozen_path':original_dir+'/sources/'+logical,**ref})
  all_sources+=1;external+=int(ref['packet_path'].startswith('../'))
 write(target/'source-map.json',{'schema_version':1,'source_count':len(mapping),'original_directory':original_dir,
   'resolution':'packet_path is relative to published packet root; sibling indices are hash pinned; original paths are preserved verbatim','sources':mapping})
 raw=src/'native.log';assert sha(raw)==result['raw_log_sha256']==raw_pin
 if raw.stat().st_size>8*1048576:
  gz=target/'native.log.gz'
  if not gz.exists():
   with raw.open('rb') as inp,gz.open('wb') as out:
    with gzip.GzipFile(filename='',mode='wb',fileobj=out,compresslevel=6,mtime=0) as z:shutil.copyfileobj(inp,z,1048576)
  h=hashlib.sha256();size=0
  with gzip.open(gz,'rb') as f:
   for b in iter(lambda:f.read(1048576),b''):h.update(b);size+=len(b)
  assert size==raw.stat().st_size and h.hexdigest()==raw_pin
  log={'portable_path':gz.relative_to(OUT).as_posix(),'encoding':'gzip','compressed_bytes':gz.stat().st_size,'compressed_sha256':sha(gz),'original_bytes':size,'original_sha256':raw_pin,'decompression_verified':True}
  write(target/'native-log-encoding.json',log)
 else:
  copy(raw,target/'native.log');log={'portable_path':(target/'native.log').relative_to(OUT).as_posix(),'encoding':'identity','original_bytes':raw.stat().st_size,'original_sha256':raw_pin}
 diags=[];footers=[];failures=[];passes=0
 with raw.open(errors='replace') as f:
  for n,line in enumerate(f,1):
   passes+=int(line.startswith('PASS:'))
   if line.startswith(('SCRIPT ERROR:','ERROR:','WARNING:')):diags.append(line.rstrip())
   if line.startswith(('Crystalman ','Captured rule ')):footers.append(line.rstrip())
   if 'FAIL:' in line:failures.append({'line':n,'text':line.rstrip()})
 assert diags==result['diagnostics'] and footers==result['footers']
 phase=re.search(r': (\d+) checks/(\d+) failures/(\d+) native ticks',footers[-1]) if footers else None
 entry=re.search(r': stage(\d+) (\d+) checks/(\d+) failures',footers[-1]) if footers else None
 clean=result['exit_code']==0 and not diags
 classification='closed_clean_import' if name==RUNS[0][0].split('/')[-1] else ('closed_clean_focused_original' if clean else ('closed_exit0_nonclean_diagnostic' if result['exit_code']==0 else 'closed_failed_original'))
 runs.append({'name':name,'classification':classification,'original_directory':original_dir,
  'result_path':'runs/'+name+'/result.json','command_path':'runs/'+name+'/command.json','manifest_path':'runs/'+name+'/source-freeze.json','source_map_path':'runs/'+name+'/source-map.json',
  'closed_at_original':result['closed_at'],'command':result['command'],'exit_code':result['exit_code'],'source_count':len(mapping),
  'baseline':freeze['baseline'],'api_revision':freeze['api_revision'],'owned_head_original':freeze['owned_head'],
  'native_footers':footers,'checks':int(phase[1]) if phase else int(entry[2]) if entry else None,'failures':int(phase[2]) if phase else int(entry[3]) if entry else None,
  'stage':int(entry[1]) if entry else None,'actual_native_ticks':int(phase[3]) if phase else None,'pass_lines':passes,
  'error_warning_script_diagnostic_lines':len(diags),'diagnostic_counts':dict(collections.Counter(diags)),'failure_lines':failures,
  'original_source_changes':[],'prior_uid_count':result['prior_uid_count'],'current_uid_count':result['current_uid_count'],'new_uid_paths':result['new_uid_paths'],'log':log})
 print('Preserved original:',original_dir,classification,len(mapping),flush=True)

assert len(runs)==18
final=runs[-1];assert final['checks']==770 and final['failures']==0 and final['actual_native_ticks']==675 and final['classification']=='closed_clean_focused_original'
imp=load(ROOT/RUNS[0][0]/'result.json');assert imp['prior_uid_count']==476 and imp['current_uid_count']==491 and len(imp['new_uid_paths'])==15
new_uid_rows=[]
for logical in imp['new_uid_paths']:
 frozen=ROOT/RUNS[1][0]/'sources'/logical;assert sha(frozen)==imp['all_current_uid_sha256'][logical]
 new_uid_rows.append({'path':logical,'sha256':sha(frozen)})
for logical in ['docs/acts/act3/A3_L5_PARENT_NATIVE_20261013.md','.cinder/crystalman-full-parent-current-recovery.md',
 '.cinder/crystalman-parent-explicit-disposal-review.json','.cinder/crystalman-parent-initial-view-observation-review.json',
 '.cinder/crystalman-parent-preview-difficulty-correction.json','.cinder/run_crystalman_parent_native.py']:
 copy(ROOT/logical,OUT/'custody'/Path(logical).name)

limits=['original Shared55 only; no Shared56 execution credit','later-stage fixtures explicitly declare prior regular-enemy history',
 'framing-state optics/transport unverified: both observed real recording routes advanced directly to warning',
 'regular priority/journal check unverified by this packet','no representative actual portrait art approval or relevant equipment extremes',
 'whole-route/full-playthrough behavior untested; no full-playthrough acceptance gate','no independent Integration or full A3-L5 acceptance']
write(OUT/'verification.json',{'status':'ORIGINAL_CLOSED_SHARED55_CUSTODY_VERIFIED','all_explicit_originals_closed':True,
 'active_source_read':False,'tracked_edits':False,'engine_or_allocation':False,'new_execution_credit':False,
 'prior_packet_indices_verified':prior_checks,'prior_source_referents_verified':prior_refs,'original_run_count':len(runs),
 'new_original_source_references_verified':all_sources,'new_unique_source_blobs':len(new_blobs),'external_same_byte_source_references':external,
 'original_prior_uid_receipt_references_verified':uid_refs,'import_prior_uids_exact':476,'genuine_import_generated_uids':new_uid_rows,
 'import_unique_uids_after':491,'raw_originals_and_diagnostics_and_footer_match_results':True,'nested_original_directory_preserved':True,
 'limitations':limits})
rows='\n'.join('| '+r['name']+' | '+str(r['exit_code'])+' | '+str(r['checks'])+'/'+str(r['failures'])+' | '+str(r['error_warning_script_diagnostic_lines'])+' | '+str(r['source_count'])+' |' for r in runs)
(OUT/'README.md').write_text('''# Crystalman original full-parent focused native custody

This packet preserves eighteen explicitly closed original runs on Shared55
f8b984a2a5371cae3f1deef8aa394bb892f28e78. It grants no new execution or
acceptance credit. Shared56 adoption does not change these original source pins.

| Original run | Exit | Checks/failures | Diagnostic lines | Frozen sources |
| --- | --- | --- | --- | --- |
'''+rows+'''

The final original real-phase fixture reports 770 checks, zero failures and 675 native
ticks with no script/resource/warning diagnostics. It earns both captured phases,
ordinary tether releases and successor saves from explicitly declared earlier
regular-enemy history. It does not prove a completed route. Entry/coda selectors
likewise declare their prior history. All earlier failed originals remain failed;
the initial-view 23/0 exit0 result retains its cleanup error and is explicitly
classified nonclean. Parse/cleanup and camera diagnostic runs are retained unchanged.

Both observed real recording routes advance directly to warning, so framing-state
optics and transport remain unverified. This packet does not establish regular
priority/journal behavior, actual portrait art fidelity, equipment extremes,
whole-route behavior, human balance or independent Integration/full level acceptance.
Full-playthrough behavior remains untested and is not an acceptance gate.

Every original result, command, prior-UID receipt, source freeze and raw log is copied
byte-exact. Every frozen source retains its logical and original physical path.
The actual nested .cinder/.cinder/crystalman-parent-phase1-seed-diagnostic-native
path is preserved verbatim, with a portable run basename only for packaging. Identical
source bytes reference five earlier hash-pinned sibling packets; every new byte has
one local SHA-256 blob. This deduplication does not relabel earlier test scope.
Resolve source-map packet_path relative to the published packet root; while ignored,
external ../A3-L5-* references resolve under assets/acts/act3/evidence. Earlier
artifact and source referents are verified, without gameplay or broad design audit.
Logs above eight MiB use lossless gzip with independently verified original
decompression; all smaller logs are unchanged copies. No original is truncated,
normalized, deleted or replaced by a passing successor.

The original necessary import preserves 476 prior UIDs and generates fifteen genuine
new owned script UIDs, giving 491 unique values with no collision. Subsequent original
jobs preserve their 491 UID bytes exactly. These import/UID receipts are custody,
not gameplay proof. The scoped owner report and correction receipts are historical
copies. Root owns later publication, snapshot work, source changes and acceptance.
''')
artifacts=[record(p) for p in sorted(OUT.rglob('*')) if p.is_file() and p.relative_to(OUT).as_posix() not in ['index.json','READY.json']]
index={'schema_version':1,'level_id':'A3-L5','created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'scope':'Original full-parent focused Shared55 native/import custody, all failures retained; no new execution or level acceptance.',
 'baseline':BASELINE,'api_revision':'campaign-shared-55','prior_packet_indices':prior_checks,'runs':runs,
 'source_reference_count':all_sources,'new_unique_source_blobs':len(new_blobs),'external_same_byte_source_references':external,
 'artifact_count_excluding_index_and_READY':len(artifacts),'artifacts':artifacts,'limitations':limits}
for a in artifacts:
 p=within(OUT/a['path'],OUT);assert p.stat().st_size==a['bytes'] and sha(p)==a['sha256']
for r in runs:
 for a in load(OUT/r['source_map_path'])['sources']:
  p=EVIDENCE/a['packet_path'][3:] if a['packet_path'].startswith('../') else OUT/a['packet_path']
  assert p.stat().st_size==a['bytes'] and sha(p)==a['sha256']
  if 'packet_index_path' in a:assert sha(EVIDENCE/a['packet_index_path'][3:])==a['packet_index_sha256']
write(OUT/'index.json',index)
ready={'status':'READY_FOR_ROOT_REVIEW_AND_LATER_PUBLICATION','stage_root':str(OUT),'index_sha256':sha(OUT/'index.json'),
 'original_run_count':len(runs),'source_reference_count':all_sources,'new_unique_source_blobs':len(new_blobs),
 'external_same_byte_source_references':external,'physical_file_count_including_index_and_READY':len(artifacts)+2,
 'artifact_count_excluding_index_and_READY':len(artifacts),'all_originals_and_referents_verified':True,
 'active_source_read':False,'tracked_edits':False,'engine_or_allocation':False,'new_execution_credit':False,
 'scope':'original Shared55 full-parent custody; framing/art/priority/whole-route/acceptance limitations remain'}
write(OUT/'READY.json',ready);print(json.dumps(ready,indent=2),flush=True)
