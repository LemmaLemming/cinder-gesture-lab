from pathlib import Path
import json,subprocess,sys
j=json.loads(Path('.cinder/cue-bits-native1-submission.json').read_text())
p=subprocess.Popen(j['argv'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
with Path('.cinder/cue-bits-native1.wrapper.log').open('wb') as out:
 for line in iter(p.stdout.readline,b''):
  out.write(line);out.flush();sys.stdout.buffer.write(line);sys.stdout.buffer.flush()
sys.exit(p.wait())
