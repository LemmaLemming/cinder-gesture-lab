from pathlib import Path
import json,hashlib,subprocess,sys,datetime
r=Path.cwd(); manifest=r/'.cinder/a1-l2-challenge-portrait2-source/manifest.json'; m=json.loads(manifest.read_text())
def verify():
 for row in m['files']:
  for p in [r/row['path'],manifest.parent/row['archived_path']]:
   b=p.read_bytes(); assert len(b)==row['bytes'] and hashlib.sha256(b).hexdigest()==row['sha256'],str(p)
verify()
log=r/'.cinder/a1-l2-challenge-portrait2-wrapper.log'; assert not log.exists()
cmd=[sys.executable,'scripts/dev/dev.py','engine','--path','.','--script','res://tests/act1_l2_challenge_portrait_smoke.gd']
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
with log.open('xb') as f:
 child=subprocess.Popen(cmd,cwd=r,stdout=f,stderr=subprocess.STDOUT); code=child.wait()
verify()
raw=log.read_bytes(); text=raw.decode('utf-8','replace')
result={'schema_version':1,'started_at':started,'closed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':cmd,'child_pid':child.pid,'returncode':code,'source_manifest':str(manifest.relative_to(r)),'source_manifest_sha256':hashlib.sha256(manifest.read_bytes()).hexdigest(),'source_count':len(m['files']),'original_archive_current_match':True,'wrapper_log':str(log.relative_to(r)),'wrapper_log_bytes':len(raw),'wrapper_log_sha256':hashlib.sha256(raw).hexdigest(),'scope':'One actual graphical Challenge starter native component, actual firstB paused prefix and rendered540x1170 portrait. Only TEST Pause overlay hidden/restored for capture; exact native unit/resources/geometry/Script/HUD/input/model/disk and zero callback controls. No fullroute/finale defeat/exit/allkits/humanbalance/performance/nativefocus override; actual image inspection separate.'}
(r/'.cinder/a1-l2-challenge-portrait2-result.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
for line in text.splitlines():
 if 'FAIL:' in line or 'SCRIPT ERROR' in line or 'Parse Error' in line or ('checks' in line and 'failures' in line): print(line)
sys.exit(1 if any(t in raw.decode('utf-8','replace') for t in ['SCRIPT ERROR','Parse Error','FAIL:']) else code)
