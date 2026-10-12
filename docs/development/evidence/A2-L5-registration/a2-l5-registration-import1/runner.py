from pathlib import Path
import json,hashlib,subprocess,sys,datetime,os
root=Path.cwd();manifest=root/'.cinder/a2-l5-registration-import1-source/manifest.json';md=json.loads(manifest.read_text());log=root/'.cinder/a2-l5-registration-import1-wrapper.log';assert not log.exists()
for row in md['files']:
 for p in [root/row['path'],manifest.parent/row['archived_path']]:assert hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],str(p)
start=datetime.datetime.now(datetime.timezone.utc).isoformat();cmd=[sys.executable,'scripts/dev/dev.py','import']
with log.open('xb') as f:
 child=subprocess.Popen(cmd,cwd=root,stdout=f,stderr=subprocess.STDOUT);code=child.wait()
for row in md['files']:
 p=manifest.parent/row['archived_path'];assert hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],str(p)
 if row['path']!='.godot/global_script_class_cache.cfg':assert hashlib.sha256((root/row['path']).read_bytes()).hexdigest()==row['sha256'],row['path']
uid=[]
for folder,dirs,files in os.walk(root):
 p=Path(folder)
 if p!=root and (p/'.gdignore').exists():dirs[:]=[];continue
 dirs[:]=[d for d in dirs if d not in {'.git','.godot','.tools','.cinder','captures','exports','__pycache__'}]
 for name in files:
  if name.endswith('.uid'):
   fp=p/name;uid.append({'path':str(fp.relative_to(root)),'sha256':hashlib.sha256(fp.read_bytes()).hexdigest(),'uid':fp.read_text().strip()})
before={r['path']:r for r in md['active_uid_before']};after={r['path']:r for r in uid};assert all(after.get(p)==r for p,r in before.items());added=[r for r in uid if r['path'] not in before];assert len({r['uid'] for r in uid})==len(uid)
raw=log.read_bytes();result={'started_at':start,'closed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':cmd,'child_pid':child.pid,'returncode':code,'source_count':len(md['files']),'source_manifest':str(manifest.relative_to(root)),'source_manifest_sha256':hashlib.sha256(manifest.read_bytes()).hexdigest(),'wrapper_log':str(log.relative_to(root)),'wrapper_log_sha256':hashlib.sha256(raw).hexdigest(),'wrapper_log_bytes':len(raw),'prior_active_uid_count':len(before),'current_active_uid_count':len(after),'all_prior_uid_bytes_retained':True,'added_uid_rows':added,'collisions':0,'scope':md['scope']}
(root/'.cinder/a2-l5-registration-import1-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));sys.exit(code)
