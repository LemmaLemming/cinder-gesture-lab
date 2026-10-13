from pathlib import Path
import datetime, hashlib, json, os, stat, subprocess, sys, time
ROOT=Path.cwd(); OUT=ROOT/'.cinder/shared53-root-import'
COMMAND=['python3','scripts/dev/dev.py','import']
EXCLUDE={'.git','.godot','.tools','.cinder','exports','captures','__pycache__'}
PROTECTED=['project.godot','.cinder/local.json','.gitignore','data/design/player_equipment.json','data/design/difficulty_profiles.json','data/design/equipment_claims.json','data/design/ability_usage.json','data/campaign/registry.json']
def utc(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def row(p):
 b=p.read_bytes();return {'path':str(p.relative_to(ROOT)),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'mode':format(stat.S_IMODE(p.stat().st_mode),'04o')}
def inventory():
 native=[];uids=[];sidecars=[];ignored=[]
 for folder,dirs,files in os.walk(ROOT):
  p=Path(folder)
  if p!=ROOT and (p/'.gdignore').exists():
   ignored.append({'path':str(p.relative_to(ROOT)),'classification':'Native .gdignore boundary; historical/evidence UID assets inside are excluded, not enumerated or counted.'});dirs[:]=[];continue
  dirs[:]=[d for d in dirs if d not in EXCLUDE]
  for name in files:
   q=p/name;rel=q.relative_to(ROOT)
   if name.endswith('.uid'):
    r=row(q);r['uid']=q.read_text().strip();uids.append(r)
   elif rel.parts[0] in {'scripts','scenes','assets','tests','data'}:
    if name.endswith('.import'):sidecars.append(row(q))
    elif not name.endswith('.lock') and name!='.DS_Store':native.append(row(q))
 protected=[row(ROOT/x) for x in PROTECTED]
 cache=[]
 for name in ['.godot/global_script_class_cache.cfg','.godot/uid_cache.bin']:
  p=ROOT/name
  if p.exists():cache.append(row(p))
 return {'captured_at':utc(),'native_runtime_scope':'All active files under scripts/scenes/assets/tests/data, except native .gdignore boundaries, volatile locks, .uid/.import metadata. Protected config/design/registry files separately checked; docs/archive/private/tool/cache banks excluded.','active_native_files':sorted(native,key=lambda r:r['path']),'active_uids':sorted(uids,key=lambda r:r['path']),'active_import_sidecars':sorted(sidecars,key=lambda r:r['path']),'protected_settings_ledger_catalogue_registry':protected,'selected_generated_cache':cache,'ignored_native_boundaries':sorted(ignored,key=lambda r:r['path']),'archive_uid_assets_counted':False}
def write(name,value):
 p=OUT/name;assert not p.exists();p.write_text(json.dumps(value,indent=2)+'\n');return row(p)
def compare(old,new):
 a={r['path']:r for r in old};b={r['path']:r for r in new}
 return {'removed':sorted(set(a)-set(b)),'added':[b[k] for k in sorted(set(b)-set(a))],'changed':[{'path':k,'before':a[k],'after':b[k]} for k in sorted(set(a)&set(b)) if a[k]!=b[k]]}
before=inventory();assert len(before['active_uids'])==445,'Unexpected prior UID inventory: stop before import';assert len({r['uid'] for r in before['active_uids']})==445,'Prior UID collision: stop before import'
before_record=write('before.json',before)
submission={'submitted_at':utc(),'command':COMMAND,'cwd':str(ROOT),'scope':'ONLY canonical queued headless import; dev.py owns shared lock and300-second deadline starts after lock acquisition. No suite/editor/foreign process change.','before_inventory':before_record,'driver_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
write('submission.json',submission)
print('Canonical command: python3 scripts/dev/dev.py import',flush=True)
print('Prior inventory: %d active runtime files;445 genuine active UIDs; archived/historical .gdignore banks excluded.'%len(before['active_native_files']),flush=True)
started=utc();clock=time.monotonic();rawpath=OUT/'original-output.log';assert not rawpath.exists()
with rawpath.open('xb') as raw:
 child=subprocess.Popen(COMMAND,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 write('child-submission.json',{'started_at':started,'child_pid':child.pid,'command':COMMAND,'cwd':str(ROOT),'deadline_owner':'Canonical scripts/dev/dev.py import, not queue wait.'})
 while True:
  block=child.stdout.read1(65536)
  if not block:break
  raw.write(block);raw.flush();sys.stdout.buffer.write(block);sys.stdout.buffer.flush()
 code=child.wait()
closed=utc();after=inventory();after_record=write('after.json',after)
deltas={k:compare(before[k],after[k]) for k in ['active_native_files','active_uids','active_import_sidecars','protected_settings_ledger_catalogue_registry','selected_generated_cache']}
text=rawpath.read_text(errors='replace');diagnostics=[s for s in text.splitlines() if s.startswith(('ERROR:','WARNING:','SCRIPT ERROR:')) or 'Parse Error' in s or 'Compile Error' in s or 'Unclaimed StringName' in s or 'ObjectDB instances leaked' in s]
uid_values=[r['uid'] for r in after['active_uids']];uid_unique=len(set(uid_values))==len(uid_values)
closure={'started_at':started,'closed_at':closed,'elapsed_seconds_including_queue':time.monotonic()-clock,'actual_command':COMMAND,'cwd':str(ROOT),'child_pid':child.pid,'actual_terminal_exit':code,'owned_child_closed':child.poll() is not None,'original_merged_output':row(rawpath),'before_inventory':before_record,'after_inventory':after_record,'deltas':deltas,'diagnostic_lines':diagnostics,'prior_uid_count':445,'after_active_uid_count':len(uid_values),'after_uid_values_unique':uid_unique,'native_runtime_unchanged':not any(deltas['active_native_files'].values()),'protected_settings_ledgers_unchanged':not any(deltas['protected_settings_ledger_catalogue_registry'].values()),'all_prior_uid_bytes_and_modes_unchanged':not deltas['active_uids']['removed'] and not deltas['active_uids']['changed'],'scope':'Necessary primary import/cache/metadata refresh only. No gameplay/registration/portrait/suite proof; prior delegated canonical O2 registration41/0 not repeated. Historical/archival UID assets under .gdignore boundaries are not active counts. Import-generated cache/sidecar deltas are separate from physical runtime sources.'}
write('closure.json',closure)
print('Import terminal exit%d; active UIDs%d; native runtime unchanged=%s; protected ledgers/settings unchanged=%s; diagnostic lines%d.'%(code,len(uid_values),closure['native_runtime_unchanged'],closure['protected_settings_ledgers_unchanged'],len(diagnostics)),flush=True)
sys.exit(code if code else (1 if diagnostics or not closure['native_runtime_unchanged'] or not closure['protected_settings_ledgers_unchanged'] or not closure['all_prior_uid_bytes_and_modes_unchanged'] or not uid_unique else 0))
