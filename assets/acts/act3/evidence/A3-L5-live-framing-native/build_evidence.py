"""Argument-driven custody packager. No engine, network, allocation or tracked writes.

Default mode stages only explicitly named closed originals. --seal additionally
requires a Root closure report, complete run hashes and all existing staged runs.
"""
from pathlib import Path
import argparse
import collections
import datetime
import gzip
import hashlib
import json
import re
import shutil

ROOT=Path('/Users/howardchen/.codex/worktrees/campaign-act3/video game idea')
PLAN=ROOT/'.cinder/a3-l5-live-framing-evidence-plan'
EVIDENCE=ROOT/'assets/acts/act3/evidence'
BASELINE='26f59b28007c68872b1a9870db675b5ed2f3c2e4'
API='campaign-shared-56'
PRIOR={
 'A3-L5-first-capture-rule':'451eab12e4532df84e90d9cde5320fc1ee3824d6f89756f805a1ddf6895ee1ac',
 'A3-L5-public-clock-join':'0f01194ae5bbbf4abbbfe16deee790a4d224fffdd7295fec7b75a4e5d0e4b059',
 'A3-L5-native-portraits':'e1f8bc55065b4006e7249a252e75420ea12814c6cdb775b6bc08993c2b61a165',
 'A3-L5-two-slot-rule':'53be11ab68f72cdee375540e4ff6d459423b565f0d8d0c96924b464df3c7cba9',
 'A3-L5-local-codec':'9880a6fddc2e1a5b53893a5356f6691b83f91a6d2395e0ac568ce2eaa021d2fa',
 'A3-L5-parent-native':'68ea87693d8aed8efe0abd64e2accdb6bbc0c34478cc88c9b8d1b8426e7fe8c4',
 'A3-L5-shared56-native':'45ede48933f27667c55592621f777bee9a738efbdab9758d9d6c4a11da86318c',
 'A3-L5-paused-registration-native':'d1a9fcf39b295908482a7e64aea473a7fc1ea5845ddf676f9d8199ce3bc35b2e',
}
CACHE={}
def digest(p):
 p=p.resolve();st=p.stat();key=(str(p),st.st_size,st.st_mtime_ns)
 if key not in CACHE:
  h=hashlib.sha256()
  with p.open('rb') as f:
   for b in iter(lambda:f.read(1048576),b''):h.update(b)
  CACHE[key]=h.hexdigest()
 return CACHE[key]
def load(p):return json.loads(p.read_text())
def bounded(p,base):
 p=p.resolve();assert p.is_relative_to(base.resolve()),('path escape',p,base);return p
def write(p,value):
 p.parent.mkdir(parents=True,exist_ok=True);tmp=p.with_name(p.name+'.tmp')
 tmp.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n');tmp.replace(p)
def exact(src,dst):
 assert src.is_file() and not src.is_symlink(),('not regular original',src)
 dst.parent.mkdir(parents=True,exist_ok=True)
 if dst.exists():assert dst.stat().st_size==src.stat().st_size and digest(dst)==digest(src),('would overwrite original bytes',dst)
 else:shutil.copy2(src,dst)
 assert dst.stat().st_size==src.stat().st_size and digest(dst)==digest(src)
def record(p,out):return {'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':digest(p)}

def incomplete_receipt(row,src,raw,config_path):
 # This is an explicit Root-selected custody branch, NEVER a missing-result fallback.
 assert config_path is not None,'incomplete_run requires an explicit runs-file configuration'
 spec=row['incomplete_run']
 assert isinstance(spec,dict) and set(spec)=={'receipt_path','receipt_sha256'},'closed explicit incomplete_run receipt configuration required'
 assert isinstance(row.get('raw_log_sha256'),str) and re.fullmatch(r'[0-9a-f]{64}',row['raw_log_sha256']),'incomplete run requires a pinned original raw log'
 assert isinstance(spec['receipt_path'],str) and spec['receipt_path'],'explicit original incomplete receipt path required'
 assert isinstance(spec['receipt_sha256'],str) and re.fullmatch(r'[0-9a-f]{64}',spec['receipt_sha256']),'incomplete run requires a pinned original receipt'
 receipt_path=bounded(src/spec['receipt_path'],src)
 assert receipt_path.is_file() and not receipt_path.is_symlink(),'regular original incomplete receipt required'
 assert not any(part in {'sources','.godot'} for part in receipt_path.relative_to(src).parts),'incomplete receipt must be a retained non-source sidecar'
 assert not (src/'result.json').exists(),'incomplete branch must not replace an existing native result'
 assert raw.is_file() and not raw.is_symlink(),'regular preserved original raw log required'
 assert digest(receipt_path)==spec['receipt_sha256'],'Root incomplete receipt pin differs'
 receipt=load(receipt_path)
 assert isinstance(receipt,dict) and receipt.get('classification')=='environment/incomplete logging','explicit incomplete environment receipt required'
 assert isinstance(receipt.get('recorded_at'),str) and receipt['recorded_at'],'original incomplete receipt timestamp required'
 assert 'native_exit_code' in receipt and receipt['native_exit_code'] is None,'native exit must remain explicitly unknown'
 assert receipt.get('footer_present') is False,'incomplete receipt cannot claim a native footer'
 assert isinstance(receipt.get('exception'),str) and receipt['exception'],'original environment exception required'
 assert isinstance(receipt.get('scope'),str) and receipt['scope'],'original process-closure scope required'
 assert type(receipt.get('raw_bytes')) is int and receipt['raw_bytes']==raw.stat().st_size,'incomplete receipt raw byte count differs'
 assert receipt.get('raw_log_sha256')==row['raw_log_sha256']==digest(raw),'incomplete receipt/raw/config hash join differs'
 return receipt_path,receipt

def build(args):
 if args.runs_file:
  config_path=Path(args.runs_file).resolve();config=load(config_path);selected=config['runs']
 else:
  config_path=None;config={};selected=[{'original_directory':p} for p in args.run]
 selected=[{'original_directory':row} if isinstance(row,str) else row for row in selected]
 assert selected,'explicit closed-run list is empty'
 if args.seal:
  assert config_path and config.get('root_reported_all_listed_jobs_closed') is True,'--seal requires explicit Root closure report'
  assert all(isinstance(row.get('raw_log_sha256'),str) for row in selected),'Root must pin every closed raw log for --seal'
 folder=config.get('publication_folder',args.publication_folder)
 assert re.fullmatch(r'A3-L5-[A-Za-z0-9-]+',folder),'bounded A3-L5 publication folder required'
 out=PLAN/args.packet_subdirectory
 bounded(out,PLAN);assert out.resolve()!=PLAN.resolve()
 assert not (out/'READY.json').exists(),'sealed packet is immutable'
 names=[row.get('packet_run_name',Path(row['original_directory']).name) for row in selected]
 assert len(set(names))==len(names),'run basenames collide; supply unique packet_run_name values'
 assert all(re.fullmatch(r'[A-Za-z0-9_-]+',n) for n in names)
 if (out/'runs').exists():
  assert {p.name for p in (out/'runs').iterdir() if p.is_dir()}.issubset(set(names)),'append-only staging: do not remove earlier failed/original runs'
 out.mkdir(parents=True,exist_ok=True);(out/'.gdignore').write_bytes(b'')
 exact(Path(__file__),out/'build_evidence.py')
 config_receipt='custody/closed-run-lists/'+digest(config_path)+'.json' if config_path else None
 if config_path:exact(config_path,out/config_receipt)
 catalogue={};prior_checks=[];prior_refs=0
 for name,pin in PRIOR.items():
  packet=EVIDENCE/name;assert digest(packet/'index.json')==pin,('prior index pin',name)
  index=load(packet/'index.json')
  for a in index['artifacts']:
   p=bounded(packet/a['path'],EVIDENCE)
   assert p.is_file() and p.stat().st_size==a['bytes'] and digest(p)==a['sha256'],('prior artifact',name,a['path'])
   if a['path'].startswith('source-blobs/'):
    catalogue.setdefault(a['sha256'],{'packet_path':'../'+name+'/'+a['path'],'bytes':a['bytes'],'sha256':a['sha256'],'packet_index_path':'../'+name+'/index.json','packet_index_sha256':pin})
  maps=[]
  for p in sorted(packet.rglob('source-map.json')):
   refs=load(p)['sources'];assert load(p).get('source_count',len(refs))==len(refs)
   for a in refs:
    q=bounded(packet/a['packet_path'],EVIDENCE)
    assert q.is_file() and q.stat().st_size==a['bytes'] and digest(q)==a['sha256']
    physical=q.relative_to(EVIDENCE).as_posix();owner=physical.split('/')[0]
    catalogue.setdefault(a['sha256'],{'packet_path':'../'+physical,'bytes':a['bytes'],'sha256':a['sha256'],'packet_index_path':'../'+owner+'/index.json','packet_index_sha256':digest(EVIDENCE/owner/'index.json')})
   prior_refs+=len(refs);maps.append({'path':p.relative_to(packet).as_posix(),'sha256':digest(p),'source_count':len(refs)})
  for a in index.get('prior_packet_indices',[]):assert digest(bounded(packet/a['path'],EVIDENCE))==a['sha256']
  prior_checks.append({'path':'../'+name+'/index.json','sha256':pin,'artifacts_verified':len(index['artifacts']),'source_maps_verified':maps})

 new_blobs=set();all_sources=0;external=0;records=[]
 for row,name in zip(selected,names):
  literal=row['original_directory'];src=bounded(ROOT/literal,ROOT/'.cinder')
  assert not src.is_relative_to(PLAN.resolve()),'source run must not be output staging'
  is_incomplete='incomplete_run' in row
  if is_incomplete:
   raw=src/'native.log'
   receipt_path,receipt=incomplete_receipt(row,src,raw,config_path)
   result=None;manifest=load(src/'source-freeze.json');target=out/'runs'/name
   raw_sha256=receipt['raw_log_sha256']
  else:
   result=load(src/'result.json');manifest=load(src/'source-freeze.json');target=out/'runs'/name
   assert result.get('closed_at'),'run has no original closure receipt'
   assert isinstance(result.get('original_source_changes'),list),'original source-change receipt required'
   assert result['frozen_inputs']==len(manifest['sources'])
   assert manifest['baseline']==BASELINE and manifest['api_revision']==API,'never attribute original sources to a later baseline'
   raw=src/'native.log';assert digest(raw)==result['raw_log_sha256']
   if row.get('raw_log_sha256'):assert digest(raw)==row['raw_log_sha256'],'Root raw pin differs'
   raw_sha256=result['raw_log_sha256']
  if is_incomplete:
   assert manifest['baseline']==BASELINE and manifest['api_revision']==API,'never attribute original sources to a later baseline'
  for required in ['command.json','source-freeze.json','prior-uids.json']:assert (src/required).is_file(),('required original missing',literal,required)
  # Retain all run files and sidecars except the deduplicated frozen source tree.
  # This includes original/current PNG, JSON, native.bin and historical result files.
  copied=[]
  for p in sorted(src.rglob('*')):
   if not p.is_file():continue
   rel=p.relative_to(src)
   if rel.parts[0]=='sources' or '.godot' in rel.parts:continue
   if rel.as_posix()=='native.log' and raw.stat().st_size>args.gzip_threshold_bytes:continue
   exact(p,target/rel);copied.append(record(target/rel,out))
  command=load(src/'command.json');argv=command.get('command',command.get('argv'))
  if is_incomplete:
   assert isinstance(argv,list) and argv and all(isinstance(value,str) for value in argv),'original incomplete command argv required'
   prior=load(src/'prior-uids.json')
   assert isinstance(prior,dict),'original pre-run UID census required; no end census is inferred'
  else:
   assert isinstance(argv,list) and ' '.join(argv)==result['command'],'command argv/result mismatch'
   prior=load(src/'prior-uids.json')
   assert len(prior)==result['prior_uid_count']
   observed_prior_uid_changes=[]
   for p,value in prior.items():
    pin=value['sha256'] if isinstance(value,dict) else value
    if result['all_current_uid_sha256'].get(p)!=pin:observed_prior_uid_changes.append(p)
   assert set(observed_prior_uid_changes)==set(result['prior_uid_changes']),'recorded prior UID change set differs from exact hash receipts'
  mapping=[]
  for logical,pin in manifest['sources'].items():
   frozen=bounded(src/'sources'/logical,src/'sources');assert digest(frozen)==pin,('frozen original',literal,logical)
   if pin not in catalogue:
    rel='source-blobs/'+pin+'/'+Path(logical).name;exact(frozen,out/rel)
    catalogue[pin]={'packet_path':rel,'bytes':frozen.stat().st_size,'sha256':pin};new_blobs.add(pin)
   ref=catalogue[pin];assert ref['bytes']==frozen.stat().st_size
   mapping.append({'original_logical_path':logical,'original_frozen_path':literal+'/sources/'+logical,**ref})
   all_sources+=1;external+=int(ref['packet_path'].startswith('../'))
  write(target/'source-map.json',{'schema_version':1,'source_count':len(mapping),'original_directory':literal,
   'resolution':'packet_path relative to published packet root; original paths preserved verbatim; external sibling indices hash pinned','sources':mapping})
  if raw.stat().st_size>args.gzip_threshold_bytes:
   gz=target/'native.log.gz'
   if not gz.exists():
    with raw.open('rb') as inp,gz.open('wb') as dest:
     with gzip.GzipFile(filename='',mode='wb',fileobj=dest,compresslevel=6,mtime=0) as z:shutil.copyfileobj(inp,z,1048576)
   h=hashlib.sha256();size=0
   with gzip.open(gz,'rb') as f:
    for b in iter(lambda:f.read(1048576),b''):size+=len(b);h.update(b)
   assert size==raw.stat().st_size and h.hexdigest()==raw_sha256
   log={'portable_path':gz.relative_to(out).as_posix(),'encoding':'gzip','compressed_bytes':gz.stat().st_size,'compressed_sha256':digest(gz),'original_bytes':size,'original_sha256':h.hexdigest(),'original_raw_retained_unchanged':True,'decompression_verified':True}
   write(target/'native-log-encoding.json',log)
  else:log={'portable_path':(target/'native.log').relative_to(out).as_posix(),'encoding':'identity','original_bytes':raw.stat().st_size,'original_sha256':digest(raw)}
  diagnostics=[];footers=[];passes=0;failure_lines=[]
  with raw.open(errors='replace') as f:
   for n,line in enumerate(f,1):
    passes+=int(line.startswith('PASS:'))
    if line.startswith(('SCRIPT ERROR:','ERROR:','WARNING:')):diagnostics.append(line.rstrip())
    if line.startswith(('Crystalman ','Captured rule ')):footers.append(line.rstrip())
    if 'FAIL:' in line:failure_lines.append({'line':n,'text':line.rstrip()})
  if is_incomplete:
   assert not footers,'incomplete original unexpectedly has a native footer; do not promote it'
  else:
   assert diagnostics==result['diagnostics'] and footers==result['footers'],'original diagnostics/footers mismatch'
  parsed=None
  for line in reversed(footers):
   parsed=re.search(r'(\d+) checks\s*/\s*(\d+) failures',line) or re.search(r'(\d+) checks; failures:?\s*(\d+)',line)
   if parsed:break
  if is_incomplete:
   portrait_files=[a for a in copied if '.png' in Path(a['path']).name.lower() or Path(a['path']).suffix.lower() in ['.jpg','.jpeg','.webp']]
   records.append({'name':name,'original_directory':literal,'classification':'incomplete_environment_no_native_result',
    'result_path':None,'native_result_available':False,'native_exit_code':None,'exit_code':None,
    'incomplete_receipt_path':(target/receipt_path.relative_to(src)).relative_to(out).as_posix(),'incomplete_receipt_sha256':digest(receipt_path),
    'incomplete_recorded_at_original':receipt['recorded_at'],'closed_at_original':None,'original_environment_exception':receipt['exception'],'process_closure_scope_original':receipt['scope'],
    'command_path':'runs/'+name+'/command.json','command':' '.join(argv),'manifest_path':'runs/'+name+'/source-freeze.json','source_map_path':'runs/'+name+'/source-map.json',
    'source_count':len(mapping),'baseline':manifest['baseline'],'api_revision':manifest['api_revision'],'owned_head_original':manifest['owned_head'],
    'original_footers':footers,'checks':None,'failures':None,'pass_lines':passes,'diagnostic_lines':len(diagnostics),'diagnostic_counts':dict(collections.Counter(diagnostics)),'failure_lines':failure_lines,
    'log':log,'original_run_non_source_files':copied,'portrait_and_native_sidecars':portrait_files,
    'original_source_changes':None,'prior_uid_count':len(prior),'prior_uid_changes':None,'current_uid_count':None,'new_uid_paths':None,'duplicate_uid_values':None,'end_uid_census_available':False,
    'root_scope_note':row.get('scope_note','Pinned incomplete environment receipt only; native result, exit, test footer and end UID census remain unknown.')})
   print('Copied explicitly pinned incomplete original:',literal,'incomplete_environment_no_native_result',flush=True)
  else:
   is_import=len(argv)>=2 and argv[-1]=='import'
   if result['original_source_changes'] or result['prior_uid_changes'] or result['duplicate_uid_values']:classification='closed_recorded_input_or_UID_drift_original'
   elif result['exit_code']!=0:classification='closed_failed_original'
   elif diagnostics:classification='closed_exit0_nonclean_original'
   elif is_import:classification='closed_clean_import'
   elif parsed and int(parsed[2])==0:classification='closed_clean_explicit_footer_original'
   else:classification='closed_exit0_without_qualified_footer_original'
   portrait_files=[a for a in copied if '.png' in Path(a['path']).name.lower() or Path(a['path']).suffix.lower() in ['.jpg','.jpeg','.webp']]
   records.append({'name':name,'original_directory':literal,'classification':classification,
    'result_path':'runs/'+name+'/result.json','command_path':'runs/'+name+'/command.json','manifest_path':'runs/'+name+'/source-freeze.json','source_map_path':'runs/'+name+'/source-map.json',
    'closed_at_original':result['closed_at'],'command':result['command'],'exit_code':result['exit_code'],'source_count':len(mapping),'baseline':manifest['baseline'],'api_revision':manifest['api_revision'],'owned_head_original':manifest['owned_head'],
    'original_footers':footers,'checks':int(parsed[1]) if parsed else None,'failures':int(parsed[2]) if parsed else None,'pass_lines':passes,'diagnostic_lines':len(diagnostics),'diagnostic_counts':dict(collections.Counter(diagnostics)),'failure_lines':failure_lines,
    'log':log,'original_run_non_source_files':copied,'portrait_and_native_sidecars':portrait_files,
    'original_source_changes':result['original_source_changes'],'prior_uid_count':result['prior_uid_count'],'prior_uid_changes':result['prior_uid_changes'],'current_uid_count':result['current_uid_count'],'new_uid_paths':result['new_uid_paths'],'duplicate_uid_values':result['duplicate_uid_values'],
    'root_scope_note':row.get('scope_note','No scope inferred beyond the preserved original command/result/footer.')})
   print('Copied explicitly closed original:',literal,classification,flush=True)

 for row in config.get('additional_custody',[]):
  src=bounded(ROOT/row['original_path'],ROOT);dest=bounded(out/row['packet_path'],out)
  assert row['packet_path'].startswith(('custody/','audits/','research/'))
  if row.get('sha256'):assert digest(src)==row['sha256']
  exact(src,dest)
 limits=config.get('explicit_scope_limits',[
  'original Shared56 results only; unchanged earlier evidence is not recredited',
  'failures and exit0 results without explicit clean footers remain unqualified',
  'portrait files and native sidecars preserve original declared history and visual-review limits',
  'no full-route, every-kit, art or Integration acceptance inferred by this source-custody packet',
  'no new engine work or equipment/ability allocation'])
 incomplete_count=sum(run['classification']=='incomplete_environment_no_native_result' for run in records)
 write(out/'verification.json',{'status':'ALL_SELECTED_ORIGINAL_BYTES_VERIFIED_WITH_EXPLICIT_INCOMPLETE_RUNS' if incomplete_count else 'ALL_SELECTED_CLOSED_ORIGINAL_BYTES_VERIFIED','root_reported_all_listed_jobs_closed':bool(config.get('root_reported_all_listed_jobs_closed')),
  'prior_packet_indices_and_referents_verified':prior_checks,'prior_source_references_verified':prior_refs,'selected_run_count':len(records),
  'source_references_verified':all_sources,'external_same_byte_source_references':external,'new_unique_source_blobs':len(new_blobs),
  'raw_logs_and_all_original_sidecars_exact':True,'active_job_read':False,'tracked_edits':False,'engine_or_allocation':False,'new_execution_credit':False,'limitations':limits})
 (out/'README.md').write_text('''# A3-L5 live framing original failed evidence

This packet preserves only the explicitly named CLOSED originals on Shared56
26f59b28007c68872b1a9870db675b5ed2f3c2e4. It performs source custody and grants
no new execution or acceptance credit. Each original command, result, source freeze,
prior-UID receipt, footer and diagnostic remains exact. Failed and nonclean originals
are retained without promotion. Exit0 engine jobs lacking an explicit qualified
footer are labeled separately; import success is resource custody only.

All current/original portrait PNGs, JSON receipts, native binary sidecars and other
non-source run files retain their names and bytes inside the original run's portable
directory. No image was resized, cropped, normalized or edited. A log over the chosen
size threshold is losslessly gzip encoded with original/compressed hashes and verified
decompression; its raw original remains unchanged outside this packet.

Every frozen logical/physical path retains its original attribution. Byte-identical
sources are deduplicated against eight pinned sibling packets, including the original
Shared55 parent packet, the sealed Shared56 packet and the paused-registration packet; that reference grants no later execution credit. Resolve
source-map packet_path relative to the published packet root. In this ignored draft,
external ../A3-L5-* paths instead resolve under assets/acts/act3/evidence. Newly changed
source bytes have one local hash blob. Root's closed-run list and any explicitly
selected audit/custody files are preserved verbatim. Root owns publication, test
qualification, visual review and Integration acceptance.

Scope limits supplied by Root:
'''+''.join('- '+x+'\n' for x in limits))
 if incomplete_count:
  verification=load(out/'verification.json')
  verification.update({'selected_closed_run_count':len(records)-incomplete_count,'selected_incomplete_run_count':incomplete_count,'native_result_or_end_UID_census_inferred':False})
  write(out/'verification.json',verification)
  (out/'README.md').write_text((out/'README.md').read_text().replace('This packet preserves only the explicitly named CLOSED originals on Shared56','This packet preserves explicitly named closed originals and pinned incomplete environment originals on Shared56').replace('Each original command, result, source freeze,','Each available original command, result, source freeze,'))
  with (out/'README.md').open('a') as text:
   text.write('\nExplicit incomplete environment originals have their pinned original closure receipt and truncated raw log preserved. No native result/footer is invented; native exit, test counts, source-change completion and final UID census remain unknown. Initial UID counts describe only the preserved pre-run census.\n')
 excluded={'index.json','index.DRAFT.json','READY.json','DRAFT_STATUS.json'}
 artifacts=[record(p,out) for p in sorted(out.rglob('*')) if p.is_file() and p.relative_to(out).as_posix() not in excluded]
 index={'schema_version':1,'level_id':'A3-L5','created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'scope':config.get('scope','Original Shared56 focused custody only; no additional execution or acceptance credit.'),'baseline':BASELINE,'api_revision':API,'future_publication_folder':folder,
  'root_reported_all_listed_jobs_closed':bool(config.get('root_reported_all_listed_jobs_closed')),'root_run_list_original_path':config_receipt,'prior_packet_indices':prior_checks,'runs':records,
  'source_reference_count':all_sources,'external_same_byte_source_references':external,'new_unique_source_blobs':len(new_blobs),'artifact_count_excluding_index_and_READY':len(artifacts),'artifacts':artifacts,'limitations':limits}
 if incomplete_count:
  index.update({'selected_closed_run_count':len(records)-incomplete_count,'selected_incomplete_run_count':incomplete_count,'native_result_or_end_UID_census_inferred':False})
 for a in artifacts:
  p=bounded(out/a['path'],out);assert p.stat().st_size==a['bytes'] and digest(p)==a['sha256']
 for run in records:
  for a in load(out/run['source_map_path'])['sources']:
   projected=bounded(EVIDENCE/folder/a['packet_path'],EVIDENCE)
   p=projected if a['packet_path'].startswith('../') else bounded(out/projected.relative_to((EVIDENCE/folder).resolve()),out)
   assert p.stat().st_size==a['bytes'] and digest(p)==a['sha256']
   if 'packet_index_path' in a:assert digest(bounded(EVIDENCE/folder/a['packet_index_path'],EVIDENCE))==a['packet_index_sha256']
 for row,run in zip(selected,records):
  src=bounded(ROOT/row['original_directory'],ROOT/'.cinder')
  assert digest(src/'native.log')==run['log']['original_sha256'],'original changed during packaging'
  if 'incomplete_run' in row:
   original_receipt=bounded(src/row['incomplete_run']['receipt_path'],src)
   assert digest(original_receipt)==row['incomplete_run']['receipt_sha256']==run['incomplete_receipt_sha256'],'original incomplete receipt changed during packaging'
   assert digest(bounded(out/run['incomplete_receipt_path'],out))==row['incomplete_run']['receipt_sha256'],'portable incomplete receipt differs from Root pin'
 path=out/('index.json' if args.seal else 'index.DRAFT.json');write(path,index)
 status={'status':'READY_FOR_ROOT_REVIEW_AND_PUBLICATION' if args.seal else 'STAGED_EXPLICIT_CLOSED_RUNS_NOT_SEALED','packet_root':str(out),'index_sha256':digest(path),
  'selected_closed_run_count':len(records),'source_reference_count':all_sources,'external_same_byte_source_references':external,'new_unique_source_blobs':len(new_blobs),
  'artifact_count_excluding_index_and_READY':len(artifacts),'future_publication_folder':folder,'active_job_read':False,'tracked_edits':False,'engine_or_allocation':False,'new_execution_credit':False}
 if incomplete_count:
  status['selected_closed_run_count']=len(records)-incomplete_count
  status['selected_incomplete_run_count']=incomplete_count
  status['native_result_or_end_UID_census_inferred']=False
  if not args.seal:status['status']='STAGED_EXPLICIT_ORIGINALS_WITH_PINNED_INCOMPLETE_RUNS_NOT_SEALED'
 if args.seal:
  for n in ['index.DRAFT.json','DRAFT_STATUS.json']:
   if (out/n).exists():(out/n).unlink()
  status['physical_file_count_including_index_and_READY']=len(artifacts)+2
  write(out/'READY.json',status)
 else:write(out/'DRAFT_STATUS.json',status)
 print(json.dumps(status,indent=2),flush=True)

if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__)
 group=parser.add_mutually_exclusive_group(required=True)
 group.add_argument('--run',action='append',help='Explicit CLOSED original directory relative to assigned checkout; repeatable')
 group.add_argument('--runs-file',help='Root JSON run list, optional raw pins/scope/custody; required for --seal')
 parser.add_argument('--seal',action='store_true',help='Require Root-confirmed closure and all raw pins; write immutable READY')
 parser.add_argument('--packet-subdirectory',default='packet')
 parser.add_argument('--publication-folder',default='A3-L5-live-framing-native')
 parser.add_argument('--gzip-threshold-bytes',type=int,default=8*1048576)
 args=parser.parse_args();assert args.gzip_threshold_bytes>0
 build(args)
