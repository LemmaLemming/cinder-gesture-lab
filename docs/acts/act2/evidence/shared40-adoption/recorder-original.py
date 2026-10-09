import pathlib,subprocess,json,hashlib,stat,datetime
root=pathlib.Path.cwd(); out=root/'docs/acts/act2/evidence/shared40-adoption';assert not out.exists();out.mkdir();(out/'.gdignore').write_text('');sha=lambda b:hashlib.sha256(b).hexdigest();own=('scripts/acts/act2/','scenes/acts/act2/','assets/acts/act2/','data/campaign/act2/','tests/acts/act2/','docs/acts/act2/')
def git_rows():
 rows={}
 for row in subprocess.check_output(['git','ls-files','--stage','-z']).split(b'\0'):
  if row:
   meta,p=row.split(b'\t',1);mode,blob,stage=meta.decode().split();rows[p.decode()]={'git_mode':mode,'blob':blob,'stage':stage}
 return rows
def file_record(p):
 m=stat.S_IMODE(p.stat().st_mode);return {'sha256':sha(p.read_bytes()),'mode':oct(m),'executable_bits':m&0o111}
def uid_rows():return {p.relative_to(root).as_posix():file_record(p) for folder in ('scripts','tests','assets') for p in (root/folder).rglob('*.uid') if p.name.endswith(('.gd.uid','.gdshader.uid'))}
tracked={k:v for k,v in git_rows().items() if k.startswith(own)};physical={}
for prefix in own:
 for p in (root/prefix).rglob('*'):
  if p.is_file() and not p.is_relative_to(out):physical[p.relative_to(root).as_posix()]=file_record(p)
uids=uid_rows();assert len(uids)==321;settings={p:file_record(root/p) for p in ('project.godot','.cinder/local.json','.vscode/settings.json')};pub='4b3e944595e700a2b0a5269485a4922bb8d59946';base='027dfa16e4c215ab1cc9f86bd0e4792088d16446';assert subprocess.check_output(['git','rev-parse',pub+'^'],text=True).strip()==base
incoming={}
for p in subprocess.check_output(['git','diff','--name-only',base,pub],text=True).splitlines():
 assert not p.startswith(own);mode,typ,blob,name=subprocess.check_output(['git','ls-tree',pub,'--',p],text=True).split();assert typ=='blob';incoming[p]={'git_mode':mode,'blob':blob,'sha256':sha(subprocess.check_output(['git','show',pub+':'+p]))}
assert len(incoming)==544
before={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'publication':pub,'preceding_actual_baseline':base,'before_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'before_status':subprocess.check_output(['git','status','--short'],text=True),'owned_tracked':tracked,'owned_physical':physical,'active_uid_rows':uids,'settings':settings,'incoming':incoming,'source_hold':'All owned new fixture import/native handles9973/93968 CLOSED and originals715 independently audited/sealed5f52400c. No own running/queued engine during adoption.'};(out/'before.json').write_text(json.dumps(before,indent=2,sort_keys=True)+'\n')
with (out/'merge.log').open('x') as log:result=subprocess.run(['git','merge','--no-ff',pub,'-m','Merge compatible Shared40 into Act 2 preserving content'],stdout=log,stderr=subprocess.STDOUT)
assert result.returncode==0,(out/'merge.log').read_text()
rows=git_rows();findings=[]
for p,v in tracked.items():
 if rows.get(p)!=v:findings.append('tracked:'+p)
for p,v in physical.items():
 if not(root/p).is_file() or file_record(root/p)!=v:findings.append('physical:'+p)
assert uid_rows()==uids,'UID identity set or byte/mode changed'
for p,v in settings.items():
 if file_record(root/p)!=v:findings.append('setting:'+p)
for p,v in incoming.items():
 row=rows[p];f=root/p
 if sha(f.read_bytes())!=v['sha256'] or row['git_mode']!=v['git_mode'] or row['blob']!=v['blob'] or bool(stat.S_IMODE(f.stat().st_mode)&0o111)!=(v['git_mode']=='100755'):findings.append('incoming:'+p)
assert not findings,findings
head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip();parents=subprocess.check_output(['git','show','-s','--format=%P',head],text=True).split();assert parents==[before['before_head'],pub]
r={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'Exact preserving compatible Shared40 adoption','publication':pub,'preceding_actual_baseline':base,'merge':head,'parents':parents,'before_sha256':sha((out/'before.json').read_bytes()),'merge_log_sha256':sha((out/'merge.log').read_bytes()),'owned_tracked_preserved':len(tracked),'owned_physical_preserved':len(physical),'active_script_shader_uid_bytes_modes_preserved':len(uids),'local_settings_preserved':len(settings),'incoming_exact_git_physical_modes':len(incoming),'findings':findings,'scope':'Private Authored source reference comparison and public named test mapping plus docs/frozen shared evidence only. Public/default validators/fallback/native world/source binding/controller/gear/HUD/camera/Lane unchanged. B05 uses ordinary ray/circle sources; no unchanged native/import/art check rerun. Old182/0 and focused19/1 preserve actual39/027 mechanical9ef and metadataa400 attribution. New strict parent/wholelevel production checks will receive their actual baseline.','new_shared_test_uid':'Publication adds tests/authored_source_guard_reference_smoke.gd without a UID sidecar. No import run/generated UID here; preserve/request canonical ownership if next justified new-resource import generates that shared identity.'};(out/'adoption.json').write_text(json.dumps(r,indent=2,sort_keys=True)+'\n');print(json.dumps({k:v for k,v in r.items() if k not in ('scope','new_shared_test_uid','parents')}))
