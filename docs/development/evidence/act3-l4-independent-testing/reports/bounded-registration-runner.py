from pathlib import Path
import sys,os,json,hashlib,re,subprocess,datetime,importlib.util,contextlib,time
ROOT=Path('/Users/howardchen/.codex/worktrees/level-test-act3/video game idea')
OUT=Path('/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/level-testing/act3')
EXPECTED='5f165cab8d11dc694a46e83b294a895f86b2cd42'
FIXTURE='tests/act3_l4_registration_smoke.gd'
phase=sys.argv[1];assert phase in ['import','registration']
destination=OUT/('native-'+phase);assert not destination.exists(), 'Preserve original scopes; fresh output required'
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==EXPECTED
assert hashlib.sha256((ROOT/FIXTURE).read_bytes()).hexdigest()=='04acea8c809e2c7226ec43aba940b75b14651e8776792735e9a0812aacc18ec2'
assert hashlib.sha256((ROOT/'data/campaign/registry.json').read_bytes()).hexdigest()=='4c7b75792501734a213ecbff53a565195021c55fc60eb84a8d2c0646413c72fb'
spec=importlib.util.spec_from_file_location('cinder_dev',ROOT/'scripts/dev/dev.py');dev=importlib.util.module_from_spec(spec);spec.loader.exec_module(dev)
context=dev.ProjectContext(ROOT);godot=dev.resolve_godot(context);lock=dev.shared_lock_path(ROOT)
assert str(lock)=='/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/locks/godot.lock'
assert str(context.canonical_root)=='/Users/howardchen/Documents/ChatGPT/video game idea'
args=['--headless','--path',str(ROOT),'--editor','--import','--quit'] if phase=='import' else ['--headless','--path',str(ROOT),'--resolution','340x736','--script','res://'+FIXTURE]
command=[str(godot),*args];timeout=300 if phase=='import' else 600
tracked=subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).split(b'\0');paths=[p.decode() for p in tracked if p]
live=[p for p in paths if not any(part in ['evidence','history','.godot','.git','.cinder'] for part in Path(p).parts)]
classes={}
for p in live:
 if p.endswith('.gd'):
  for name in re.findall(r'^class_name\s+(\w+)',(ROOT/p).read_text(),re.M):classes[name]=p
seeds=[FIXTURE,'project.godot','scripts/dev/dev.py','data/campaign/registry.json','data/design/player_equipment.json','.cinder/local.json']
todo=list(seeds);seen=set();missing=set()
while todo:
 p=todo.pop()
 if p in seen:continue
 source=ROOT/p
 if not source.is_file():missing.add(p);continue
 seen.add(p)
 if source.suffix in ['.gd','.tscn','.tres','.gdshader','.json'] or source.name=='project.godot':
  text=source.read_text(errors='replace')
  for ref in re.findall(r'res://([^\s"\'\)]+)',text):
   if not ref.startswith('.godot/'):todo.append(ref)
  if source.suffix=='.gd':
   for word in set(re.findall(r'\b\w+\b',text))&classes.keys():todo.append(classes[word])
 for sidecar in [p+'.uid',p+'.import']:
  if (ROOT/sidecar).is_file():todo.append(sidecar)
destination.mkdir(parents=True);(destination/'.gdignore').write_bytes(b'')
rows=[]
for p in sorted(seen):
 b=(ROOT/p).read_bytes();q=destination/'source'/p;q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(b)
 rows.append({'path':p,'frozen_path':str(q.relative_to(destination)),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
uid_before={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in live if p.endswith('.uid')}
metadata={'schema_version':1,'phase':phase,'prequeue_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate':EXPECTED,'shared_base':'16311879af3e4dde69f96574d32572796bcf0d23','content_seal':'741fe48ee2db1ad27ba6e9ce2f7c7ab0a41fb6a7','command':command,'timeout_seconds_after_lock':timeout,'cwd':str(ROOT),'canonical_root':str(context.canonical_root),'shared_lock':str(lock),'wrapper_pid':os.getpid(),'wrapper_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'engine_sha256':hashlib.sha256(godot.read_bytes()).hexdigest(),'scope':'Original prequeue literal resource/global-class dependency subset plus explicit metadata/configuration. Imported .godot cache excluded; not complete import inventory. Missing captured-preview literal paths are output save_png destinations, never seeded old screenshots. No original UID backfill.','roots':seeds,'missing_literal_references':sorted(missing),'source_rows':rows,'uid_before':uid_before}
(destination/'input.json').write_text(json.dumps(metadata,indent=2)+'\n')
class Tee:
 def __init__(self,*streams):self.streams=streams
 def write(self,data):
  for stream in self.streams:stream.write(data);stream.flush()
  return len(data)
 def flush(self):
  for stream in self.streams:stream.flush()
queue_at=time.monotonic();exit_code=None;exception=None
with (destination/'wrapper.log').open('w') as wrap,(destination/'native.log').open('w') as native:
 console=sys.stdout;error_console=sys.stderr
 with contextlib.redirect_stdout(Tee(console,wrap)),contextlib.redirect_stderr(Tee(error_console,wrap)):
  print('PREQUEUE '+json.dumps({'phase':phase,'input_rows':len(rows),'input_sha256':hashlib.sha256((destination/'input.json').read_bytes()).hexdigest(),'command':command}),flush=True)
  try:
   with dev.godot_lock(ROOT) as fd:
    acquired_at=datetime.datetime.now(datetime.timezone.utc).isoformat();wait_s=time.monotonic()-queue_at
    print('LOCK_ACQUIRED '+json.dumps({'at':acquired_at,'queue_wait_seconds':wait_s}),flush=True)
    with contextlib.redirect_stdout(Tee(console,wrap,native)):
     exit_code=dev.run_validation(command,context,fd,timeout,detect_godot_errors=True)
  except BaseException as exc:
   exception=repr(exc);raise
  finally:
   closed=datetime.datetime.now(datetime.timezone.utc).isoformat();changed=[]
   for row in rows:
    p=ROOT/row['path']
    if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=row['sha256']:changed.append(row['path'])
   current_live=[p for p in ROOT.rglob('*.uid') if not any(part in ['evidence','history','.godot','.git','.cinder'] for part in p.relative_to(ROOT).parts)]
   uid_after={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in current_live}
   uid_changed=[p for p,sha in uid_before.items() if uid_after.get(p)!=sha]
   generated={p:sha for p,sha in uid_after.items() if p not in uid_before}
   log=(destination/'native.log').read_text();diagnostics=[s for s in log.splitlines() if re.search(r'(SCRIPT ERROR:|ERROR:|WARNING:)',s)]
   result={'schema_version':1,'phase':phase,'candidate':EXPECTED,'closed_at':closed,'command':command,'timeout_seconds':timeout,'exit_code':exit_code,'exception':exception,'original_input_rows':len(rows),'input_sha256':hashlib.sha256((destination/'input.json').read_bytes()).hexdigest(),'source_changes_after':changed,'prior_uid_count':len(uid_before),'prior_uid_changes':uid_changed,'new_uids':generated,'uid_after_count':len(uid_after),'raw_log_sha256':hashlib.sha256((destination/'native.log').read_bytes()).hexdigest(),'diagnostic_lines':diagnostics,'footers':[s for s in log.splitlines() if re.search(r'checks.*failures|failures.*checks',s)]}
   print('CLOSED '+json.dumps(result),flush=True)
   (destination/'result.json').write_text(json.dumps(result,indent=2)+'\n')
print('RESULT_PATH '+str(destination/'result.json'),flush=True)
sys.exit(exit_code if exit_code is not None else 1)
