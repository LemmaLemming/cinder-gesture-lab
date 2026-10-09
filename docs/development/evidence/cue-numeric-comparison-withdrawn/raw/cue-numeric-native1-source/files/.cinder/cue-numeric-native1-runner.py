from pathlib import Path
import json,subprocess,sys,hashlib
j=json.loads(Path('.cinder/cue-numeric-native1-submission.json').read_text())
m=json.loads(Path(j['source_manifest']).read_text());base=Path(j['source_manifest']).parent
for row in m['files']:
 b=Path(row['path']).read_bytes();a=(base/row['archived_path']).read_bytes()
 assert len(b)==row['bytes'] and hashlib.sha256(b).hexdigest()==row['sha256'] and a==b,row['path']
print('Verified prequeue frozen inputs:',len(m['files']),flush=True)
p=subprocess.Popen(j['argv'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
with Path('.cinder/cue-numeric-native1.wrapper.log').open('wb') as out:
 for line in iter(p.stdout.readline,b''):
  out.write(line);out.flush()
  if not line.startswith((b'PASS:',b'AUTHORED_ECHO_PROFILE_JSON ')):
   sys.stdout.buffer.write(line);sys.stdout.buffer.flush()
rc=p.wait();print('Observed canonical wrapper exit:',rc,flush=True);sys.exit(rc)
