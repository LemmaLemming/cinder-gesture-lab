from pathlib import Path
import json,hashlib,subprocess,sys,datetime
r=Path.cwd(); manifest=r/'.cinder/a1-l3-import1-source/manifest.json'; m=json.loads(manifest.read_text())
def verify():
 for row in m['files']:
  for p in [r/row['path'],manifest.parent/row['archived_path']]:
   b=p.read_bytes(); assert len(b)==row['bytes'] and hashlib.sha256(b).hexdigest()==row['sha256'],str(p)
verify()
log=r/'.cinder/a1-l3-import1-wrapper.log'; assert not log.exists()
cmd=[sys.executable,'scripts/dev/dev.py','import']
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
with log.open('xb') as f:
 child=subprocess.Popen(cmd,cwd=r,stdout=f,stderr=subprocess.STDOUT); code=child.wait()
verify()
raw=log.read_bytes(); text=raw.decode('utf-8','replace')
result={'schema_version':1,'started_at':started,'closed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':cmd,'child_pid':child.pid,'returncode':code,'source_manifest':str(manifest.relative_to(r)),'source_manifest_sha256':hashlib.sha256(manifest.read_bytes()).hexdigest(),'source_count':len(m['files']),'original_archive_current_match':True,'wrapper_log':str(log.relative_to(r)),'wrapper_log_bytes':len(raw),'wrapper_log_sha256':hashlib.sha256(raw).hexdigest(),'scope':'Queued root import of exact submitted A1-L3 native actors, production alias and texture resources. Bounded source/resource import only; no new mechanics, saves, transitions or acceptance claim. Original submitted byte custody retained.'}
(r/'.cinder/a1-l3-import1-result.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
for line in text.splitlines():
 if 'FAIL:' in line or 'SCRIPT ERROR' in line or 'Parse Error' in line or ('checks' in line and 'failures' in line): print(line)
sys.exit(code)
