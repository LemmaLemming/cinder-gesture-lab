from pathlib import Path
import subprocess,sys,json,hashlib,datetime,collections
name=sys.argv[1];mode=sys.argv[2];dest=Path('.cinder')/name
roots=['tests/acts/act3/crystalman_parent_transport_smoke.gd','tests/acts/act3/crystalman_parent_phase_smoke.gd','tests/acts/act3/crystalman_regular_priority_smoke.gd','tests/acts/act3/fixtures/framing_candidate_extension.gd','scripts/dev/dev.py']
subprocess.run(['python3','.cinder/freeze_act3_target_shared55.py',str(dest),*roots],check=True)
manifest=json.loads((dest/'source-freeze.json').read_text())
for n,sha in manifest['sources'].items():assert hashlib.sha256(Path(n).read_bytes()).hexdigest()==sha,n
def uids():
 rows={}
 for prefix in ['scripts','tests','assets']:
  for p in Path(prefix).rglob('*.uid'):
   if 'evidence' in p.parts:continue
   rows[str(p)]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'value':p.read_text().strip()}
 return rows
prior=uids();(dest/'prior-uids.json').write_text(json.dumps(prior,indent=2)+'\n')
if mode=='import':command=['python3','scripts/dev/dev.py','import']
else:
 assert mode.startswith('res://tests/acts/act3/') and Path(mode.removeprefix('res://')).is_file()
 command=['python3','scripts/dev/dev.py','engine','--headless','--path','.','--script',mode]
 if sys.argv[3:]:command+=['--',*sys.argv[3:]]
(dest/'command.json').write_text(json.dumps({'command':command,'started_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'First necessary combined import/new production focused checks only; no prior component recredit.'},indent=2)+'\n')
print('Queued managed Godot job with frozen inputs.',flush=True)
diags=[];footers=[];seen=set();passes=0
with (dest/'native.log').open('w') as log:
 process=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
 for line in process.stdout:
  log.write(line);log.flush()
  if line.startswith('PASS:'):passes+=1
  if line.startswith(('SCRIPT ERROR:','ERROR:','WARNING:')):
   diags.append(line.rstrip())
   if line.rstrip() not in seen and len(seen)<10:seen.add(line.rstrip());print(line.rstrip(),flush=True)
  if line.startswith(('Crystalman ','Captured rule ')):
   footers.append(line.rstrip());print(line.rstrip(),flush=True)
 code=process.wait()
changes=[n for n,sha in manifest['sources'].items() if not Path(n).is_file() or hashlib.sha256(Path(n).read_bytes()).hexdigest()!=sha]
current=uids();changed=[n for n,row in prior.items() if current.get(n)!=row];byval={}
for n,row in current.items():byval.setdefault(row['value'],[]).append(n)
collisions={v:ns for v,ns in byval.items() if len(ns)>1}
result={'closed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':' '.join(command),'exit_code':code,'frozen_inputs':len(manifest['sources']),'original_source_changes':changes,'diagnostics':diags,'footers':footers,'raw_log_sha256':hashlib.sha256((dest/'native.log').read_bytes()).hexdigest(),'prior_uid_count':len(prior),'prior_uid_changes':changed,'new_uid_paths':sorted(set(current)-set(prior)),'current_uid_count':len(current),'duplicate_uid_values':collisions,'all_current_uid_sha256':{n:row['sha256'] for n,row in current.items()}}
(dest/'result.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['diagnostics','all_current_uid_sha256']}|{'pass_lines':passes,'diagnostic_counts':dict(collections.Counter(diags))}),flush=True)
sys.exit(code)
