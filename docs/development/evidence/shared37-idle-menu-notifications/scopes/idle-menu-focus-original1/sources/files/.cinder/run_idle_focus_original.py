from pathlib import Path
import subprocess,json,hashlib,datetime,re
r=Path.cwd();script='scripts/dev/dev.py'
jobs=[('idle-menu-focus-original1','tests/campaign_shell_smoke.gd',['--','--focus-notifications-only'])]
for name,test,args in jobs:
 scope=r/f'.cinder/{name}-source';m=json.loads((scope/'manifest.json').read_text());manifest_sha=hashlib.sha256((scope/'manifest.json').read_bytes()).hexdigest();native=f'.cinder/{name}.log';wrapper=f'.cinder/{name}-wrapper.log';closure=r/f'.cinder/{name}-closure.json';assert not closure.exists() and not (r/native).exists() and not (r/wrapper).exists()
 for row in m['files']:
  assert hashlib.sha256((r/row['path']).read_bytes()).hexdigest()==row['sha256'];assert hashlib.sha256((scope/row['archived_path']).read_bytes()).hexdigest()==row['sha256']
 argv=['python3',script,'engine','--path',str(r),'--headless','--log-file',str(r/native),'--script','res://'+test,*args]
 submission={'submitted_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_argv':argv,'source_manifest_sha256':manifest_sha,'scope':'Original published36 Shell synthetic native focus/pause notification idle-menu reproduction + actual living/fatal persistence and gesture controls; testsource newlyselected, no OSfocus/A2cause claim'};(r/f'.cinder/{name}-submission.json').write_text(json.dumps(submission,indent=2)+'\n');print(name+' submitted through canonical dev.py queue',flush=True)
 with (r/wrapper).open('wb') as h:result=subprocess.run(argv,stdout=h,stderr=subprocess.STDOUT,cwd=r)
 changed=[]
 for row in m['files']:
  if hashlib.sha256((r/row['path']).read_bytes()).hexdigest()!=row['sha256']:changed.append(row['path'])
 logs=[]
 for rel in [native,wrapper]:
  p=r/rel;b=p.read_bytes() if p.exists() else b'';s=b.decode(errors='replace');logs.append({'path':rel,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'script_errors':len(re.findall('SCRIPT ERROR:',s)),'native_errors':len(re.findall(r'(?m)^ERROR:',s)),'warnings':len(re.findall(r'(?m)^WARNING:',s)),'parse_errors':len(re.findall('Parse Error:',s)),'summaries':[line[:350] for line in s.splitlines() if 'checks,' in line and 'failures' in line]})
 receipt={**submission,'closed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit_code':result.returncode,'original_source_files':len(m['files']),'current_sources_match_originals':not changed,'changed_originals':changed,'logs':logs};closure.write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({'job':name,'exit':result.returncode,'changed_sources':changed,'logs':logs}),flush=True)
 if result.returncode or changed or any(x['script_errors'] or x['native_errors'] or x['warnings'] or x['parse_errors'] for x in logs):raise SystemExit(1)
