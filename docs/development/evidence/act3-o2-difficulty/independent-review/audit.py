from pathlib import Path
import subprocess,json,hashlib,re,stat,datetime
W=Path('/Users/howardchen/.codex/worktrees/campaign-act3/video game idea')
C='cd37db9ef36cb802826800e4ed9622cac326c914'; BASE='18b07006ea514ad9db20fd6a48a4baccfdd30970'
P='assets/acts/act3/evidence/A3-O2-arrangement-native/'
OUT=Path(__file__).parent
records=[]
def ck(ok,what,detail=None):
 records.append({'ok':bool(ok),'check':what,'detail':detail})
def sha(b):return hashlib.sha256(b).hexdigest()
def git(*a):return subprocess.check_output(['git','--no-optional-locks','-C',str(W),*a])
cache={}
def blob(path,c=C):
 key=(c,path)
 if key not in cache:cache[key]=git('show',c+':'+path)
 return cache[key]
def obj(path,c=C):return json.loads(blob(path,c))
def tree(c):
 t={}
 for row in git('ls-tree','-rz',c).split(b'\0'):
  if not row:continue
  meta,path=row.split(b'\t');mode,kind,oid=meta.decode().split();t[path.decode()]={'mode':mode,'kind':kind,'oid':oid}
 return t
def dec(x):
 if not isinstance(x,list) or not x:raise ValueError('invalid exact node')
 tag=x[0];v=x[1] if len(x)>1 else None
 if tag=='dictionary':return {k:dec(v) for k,v in v}
 if tag=='array':return [dec(a) for a in v]
 if tag=='integer':return int(v)
 if tag in ['string','boolean']:return v
 if tag=='null':return None
 return {'tag':tag,'value':v}
def exact(path):return dec(obj(path)['value'])
T=tree(C); index=obj(P+'index.json'); I=blob(P+'index.json')
ck(sha(I)=='773a96563dd8aa4e4ef3155178c895c27364a6047f9cfe87c3389e8f3ffa482a','immutable index hash')
packpaths=[x for x in T if x.startswith(P)]
ck(len(packpaths)==259,'exact pack tree count',len(packpaths))
count=0;total=0;origchecks=0
for rel,row in index['files'].items():
 path=P+rel;b=blob(path);m=T[path]
 ck(sha(b)==row['sha256'] and len(b)==row['bytes'] and m['mode']=='100'+row['mode'][-3:],'indexed Git byte/mode '+rel)
 physical=W/path
 ck(physical.is_file() and physical.read_bytes()==b and stat.S_IMODE(physical.stat().st_mode)==int(row['mode'],8),'physical byte/mode '+rel)
 for orig in row['original_absolute_paths']:
  p=Path(orig)
  ck(p.is_file() and p.read_bytes()==b,'original copy equality '+rel,orig)
  origchecks+=1
 count+=1;total+=len(b)
ck(count==257 and total==index['artifact_bytes_excluding_index_and_detached_hash'],'indexed count and byte sum',[count,total])
extra=set(packpaths)-{P+p for p in index['files']}
ck(extra=={P+'index.json',P+'index.sha256'},'only index and detached hash extra',sorted(extra))
ck(sha(I) in blob(P+'index.sha256').decode(),'detached hash agrees')
run_audits=[];joins=0;headjoins=0;frozenorigins=0
for name,row in index['runs'].items():
 native=blob(P+'runs/'+name+'/native.log').decode()
 res=obj(P+'runs/'+name+'/result.json'); src=obj(P+'runs/'+name+'/sources.json');cmd=obj(P+'runs/'+name+'/command.json')
 actual=re.findall(r'^O2 ARRANGEMENT ROW (\d+): (PASS|FAIL) (.*)$',native,re.M)
 counters=re.findall(r'^O2 arrangement(?: producer)?: (\d+) checks/(\d+) failures; scope_complete=(true|false);',native,re.M)
 diags=[s for s in native.splitlines() if s.startswith(('SCRIPT ERROR:','ERROR:','WARNING:'))]
 ck(res['native_log_sha256']==sha(native.encode()),'raw log hash '+name)
 ck(row['actual_exit_code_as_recorded']==res['actual_exit_code'],'actual process exit '+name)
 ck(row['observed_assertion_row_count']==len(actual) and row['observed_failed_assertion_row_count']==sum(x[1]=='FAIL' for x in actual),'actual row census '+name)
 ck([int(x[0]) for x in actual]==list(range(1,len(actual)+1)),'actual consecutive row ordinals '+name)
 ck(row['recorded_diagnostics']==diags==res['diagnostics'],'actual diagnostic census '+name)
 ck(row['started_head']==src['head'] and row['head_after']==res['head_after'] and row['recorded_head_drift']==(src['head']!=res['head_after']),'actual closed HEAD joins '+name)
 ck(row['recorded_source_drift']==res['selected_source_changes_during_run']==[],'reported selected source before/after delta '+name)
 ck(row['command']==cmd and cmd['argv'][:3]==['python3','scripts/dev/dev.py','import' if name=='producer-import-01' else 'engine'],'canonical queue command '+name)
 if counters:
  n,bad,complete=counters[-1]
  ck(int(n)==len(actual) and int(bad)==sum(x[1]=='FAIL' for x in actual),'terminal footer matches actual row census '+name)
  ck((res['actual_exit_code']==0)==(int(bad)==0 and complete=='true'),'native complete/exit/failure classification '+name)
  ck(row['native_footer_counters'][-1]['checks']==int(n) and row['native_footer_counters'][-1]['failures']==int(bad) and row['native_footer_counters'][-1]['scope_complete_as_printed']==complete,'indexed footer agrees '+name)
 else:ck(not actual and res['actual_exit_code']==0,'no mechanics credit for parse/import '+name)
 mapping=row['selected_source_mapping']
 ck(set(mapping)==set(src['selected_sources']),'exact source alias set '+name)
 for rel,m in mapping.items():
  b=blob(P+m['storage']);digest=sha(b)
  ck(digest==m['sha256']==src['selected_sources'][rel],'frozen source join '+name+' '+rel)
  orig=Path(m['original_frozen_blob_absolute_path']);ck(orig.is_file() and orig.read_bytes()==b,'actual original frozen source blob '+name+' '+rel)
  joins+=1;frozenorigins+=1
  # .cinder private runner has no committed identity; do not invent one.
  if not rel.startswith('.cinder/'):
   try:gb=blob(rel,src['head'])
   except subprocess.CalledProcessError:
    allowed_import=(name=='producer-import-01' and rel=='tests/acts/act3/quiet_root_circuit_arrangement_smoke.gd')
    ck(allowed_import,'explicit precommit source-only import observation '+name+' '+rel,'Original initial import is not a mechanics pass. Its then-uncommitted new fixture remains exact in the original frozen blob; no execution-HEAD Git provenance is invented.');continue
   ck(gb==b,'recorded execution HEAD source join '+name+' '+rel);headjoins+=1
 run_audits.append({'name':name,'actual_exit':res['actual_exit_code'],'checks':len(actual),'failures':sum(x[1]=='FAIL' for x in actual),'footer':counters[-1] if counters else None,'diagnostic_count':len(diags),'selected_sources':len(mapping),'execution_head':src['head']})
# Immutable old originals:19 files and no promotion before the genuine writer seal.
F='tests/acts/act3/fixtures/a3_o2_arrangement_legacy/'
manifest=exact(F+'manifest.json')
ck(sha(blob(F+'manifest.json'))=='a4dd684ee42fed0a9566d1fd3a8df2f1eacf31c31a727b290f5a26ecb49f97db','original native manifest hash')
for rel,r in manifest['files'].items():
 b=blob(F+rel)
 ck(sha(b)==r['sha256'] and len(b)==r['bytes'],'old original manifest member '+rel)
 ck(blob(F+rel,'02bc7166e6c17383af855b241cc9a06edda4178d')==b,'actual original prepromotion sealed Git bytes '+rel)
ck(blob(F+'manifest.json','02bc7166e6c17383af855b241cc9a06edda4178d')==blob(F+'manifest.json'),'old manifest itself retained from prepromotion seal')
oldsummary=[]
for sample in ['entrance','first-root-held']:
 unit=exact(F+sample+'/unit.native.json');session=exact(F+sample+'/session.native.json'); receipt=exact(F+sample+'/receipt.json');store=obj(F+sample+'/campaign.store.json');loc=unit['level']['local']
 ck(store['sha256']==sha(store['payload_json'].encode()),'old raw Store native payload checksum '+sample)
 saved=dec(json.loads(store['payload_json'])['value'])
 ck(saved==session and session['side_attempt']['snapshot']==unit,'old raw Store/session/whole native unit exact join '+sample)
 ck(store['format_version']==2 and store['generation']>0,'old actual format2 generation '+sample,store['generation'])
 ck(loc['api_revision']=='act3-quiet-root-circuit-2' and loc['schema_version']==1 and set(loc)=={'api_revision','schema_version','scenery','scheduler','sources','route'},'literal old six-key representation '+sample)
 ck(loc['scheduler']['profile']['id']=='challenge' and len(loc['sources'])==5,'genuine old Challenge profile and all5 actors '+sample)
 ck(len(receipt['actual_native_ids_decimal_text'])>=12 and all(isinstance(x,str) and x.lstrip('-').isdigit() for x in receipt['actual_native_ids_decimal_text'].values()),'original signed/text native identity sample '+sample)
 oldsummary.append({'sample':sample,'generation':store['generation'],'all_sources':list(loc['sources']),'receipt_keys':list(receipt),'whole_unit_sha256':sha(blob(F+sample+'/unit.native.json'))})
# Strict code and scope checks at exact immutable commits.
source='scripts/acts/act3/quiet_root_circuit.gd';test='tests/acts/act3/quiet_root_circuit_arrangement_smoke.gd';data='data/campaign/act3/a3_o2_encounters.json'
ck(sha(blob(source))=='b4c6238a6a37a45dca84f5b093a1b4fe4f6c54331f6121a5d7b08e8eed39ee0e','final runtime hash')
ck(sha(blob(test))=='c0ebf1934a3788dd2f694b94f427d82bde60eab110c5ac17e2cc56d5e2b7450d','final fixture hash')
ck(sha(blob(data))=='9d1d5bff20485227d8fae7e5ba6a6dd6e4ae19f1cc625d2ed4e92f4247e8dbd9','final encounter hash')
for p in [source,test,data,test+'.uid']:
 ck(blob(p,'379b264e23a2ed358b80f84405a0f325c3c9ce0d')==blob(p),'final exercised source exact '+p)
paths=git('diff','--name-only',BASE,C).decode().splitlines()
expected_prefixes=['data/campaign/act3/','docs/acts/act3/','scripts/acts/act3/','tests/acts/act3/','assets/acts/act3/']
ck(all(any(p.startswith(k) for k in expected_prefixes) for p in paths),'all amendment changes remain Act3 owned prefixes')
runtimepaths=[p for p in paths if p.startswith(('scripts/','scenes/'))]
ck(runtimepaths==[source],'sole production script changed',runtimepaths)
for p in ['scripts/acts/act3/crystalman_capture_phase.gd','scripts/acts/act3/crystalman_capture_codec.gd','scripts/acts/act3/garden_root_latcher.gd','scripts/acts/act3/sunbound_stalker.gd','scripts/combat/threat_scheduler.gd','scripts/combat/encounter_arrangement.gd','scripts/presentation/camera_framing.gd','scripts/player.gd','data/campaign/registry.json']:
 ck(blob(p,BASE)==blob(p),'unchanged protected/native/shared source '+p)
olddata=obj(data,BASE);newdata=obj(data)
ck(newdata['source_positions']==olddata['source_positions'],'canonical data anchors unchanged')
ck({k:v for k,v in olddata.items() if k not in ['scope','runtime_api']}=={k:v for k,v in newdata.items() if k not in ['scope','runtime_api','arrangement']},'only data API/scope/new arrangement added')
def funcs(raw):
 raw=raw.decode();ms=list(re.finditer(r'^(?:static )?func (\w+)\(',raw,re.M));return {m.group(1):raw[m.start():ms[i+1].start() if i+1<len(ms) else len(raw)] for i,m in enumerate(ms)}
f0=funcs(blob(source,'34c411e2'));f1=funcs(blob(source));changed=[k for k in f0 if f0[k]!=f1.get(k)]
ck(set(f0)==set(f1) and changed==['combat_response'],'earlier pure source functions identical outside owned dictionary key fix',changed)
a=funcs(blob(test,'f702be26'));b=funcs(blob(test));changed=[k for k in a if a[k]!=b.get(k)]
ck(changed==['_component_case','_component_probe_framing'],'later fixture function deltas',changed)
# _component_probe_framing is the last old function; added next helper causes separator/comment delta, strip appended explanatory comment.
ck(a['_component_portrait']==b['_component_portrait'] and all(a[k]==b[k] for k in a if k.startswith(('_ot_','_run_pure','_pure'))),'portrait and transport/pure helper bodies retained')
# Native expectation evidence compares actual canonical approval and proposal; no new inferred approval.
host=obj(P+'runs/component-after-failure-diagnostic-01/host-expectation-review.json')
auth=Path('.cinder/agent-chat/cinder-campaign/integration/messages/afb39042-38e3-4123-8a32-eab9105ea283-RESPONSE.json').read_bytes()
ck(sha(auth)==host['authorization_sha256'] and json.loads(auth)['response']==host['actual_authorization'],'actual canonical Root scope agrees with host diagnostic record')
ck(host['actual_native_exit']==1 and host['original_assertion_failed'] and host['actual_after_failure_receipt'] in blob(P+'runs/component-after-failure-diagnostic-01/native.log').decode(),'original failed946 diagnostic receipt retained verbatim')
# Exact adoption custody.
ack=Path('.cinder/agent-chat/cinder-campaign/act3/messages/05640740-09bd-470f-b824-71f2d6b9f353-ACK.json').read_bytes();ad=json.loads(ack)
ck(git('show','-s','--format=%P',ad['commit']).decode().strip().split()==ad['parents'],'actual adopted merge parents')
ck(subprocess.run(['git','--no-optional-locks','-C',str(W),'merge-base','--is-ancestor',ad['commit'],C]).returncode==0,'Shared65 merge retained as actual submission ancestor')
receipt=Path(ad['adoption_receipt']['path']).read_bytes();ck(sha(receipt)==ad['adoption_receipt']['sha256'],'actual Shared65 receipt hash')
result={'schema_version':1,'kind':'independent-read-only-a3-o2-difficulty-review','created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'submission':C,'baseline':BASE,'evidence_index_sha256':sha(I),'checks':len(records),'failed_host_checks':[r for r in records if not r['ok']],'pack':{'committed_files':len(packpaths),'indexed_members':count,'indexed_bytes':total,'actual_original_file_joins':origchecks,'source_alias_joins':joins,'recorded_head_source_joins':headjoins,'frozen_source_original_joins':frozenorigins},'runs':run_audits,'old_native_pairs':oldsummary,'changed_paths':paths,'records':records,'limits':['No engine job run.','This is host/immutable-source/evidence review, not an additional native gameplay pass.','Selected source observations are original runner preenqueue and postclosure hashes; no unsupported at-lock source capture is inferred.','Original8 accepted unchanged; authored difficulty amendment not yet Root published.']}
(OUT/'AUDIT.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:result[k] for k in ['checks','failed_host_checks','pack']},indent=2))
