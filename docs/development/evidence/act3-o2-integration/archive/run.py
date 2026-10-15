"""Root short O2 canonical registration; fixed named pins, shared Godot queue."""
import argparse, contextlib, datetime, hashlib, importlib.util, json, os, sys, time, uuid
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
TEST='tests/act3_o2_registration_smoke.gd'
ENV='CINDER_A3_O2_SHORT_REGISTRATION_REPORT'
SOURCE_NAMES=['scripts/acts/act3/quiet_root_circuit.gd','data/campaign/act3/a3_o2_encounters.json','scenes/acts/act3/a3_o2_quiet_root_circuit.tscn','tests/acts/act3/quiet_root_circuit_optional_shell.gd','tests/acts/act3/quiet_root_circuit_focused.gd','tests/acts/act3/pillars_before_time_optional_shell.gd','tests/acts/act3/pillars_before_time_focused.gd','scripts/acts/act3/living_forest_level.gd','scripts/acts/act3/living_forest.gd','scripts/acts/act3/living_forest_scenery.gd','data/campaign/act3/a3_l2_encounters.json','scenes/acts/act3/a3_l2_living_forest.tscn','scripts/acts/act3/root_latcher.gd','scripts/acts/act3/root_latcher_art.gd','scripts/acts/act3/garden_root_latcher.gd','scripts/acts/act3/sunbound_stalker.gd','scripts/combat/threat_scheduler.gd','scripts/combat/lane_mechanism.gd','scripts/combat/threat_geometry.gd','scripts/combat/body_sweep.gd','scripts/campaign/shell.gd','scripts/campaign/level.gd','scripts/campaign/registry.gd','scripts/campaign/attempts.gd','scripts/campaign/save_store.gd','scripts/campaign/exact_json.gd','scripts/campaign/snapshot_codec.gd','scripts/player.gd','scripts/game.gd','scripts/hud.gd','scripts/ui/campaign_menu.gd','scripts/equipment.gd','data/design/player_equipment.json','data/campaign/registry.json','scenes/main.tscn','project.godot','scripts/dev/dev.py',TEST,str(Path(__file__).resolve().relative_to(ROOT))]
FILES=set(SOURCE_NAMES)|{p+'.uid' for p in SOURCE_NAMES if p.endswith('.gd')}
SCOPE='Fixed named source/UID subset only; not whole dependency/import/global/resource/UID or frozenbank census. No inherited held/court/completion/contact/Replay/portrait or fullroute/FPS credit.'
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_text(json.dumps(d,indent=2)+'\n')
def observe():return {p:sha(ROOT/p) if (ROOT/p).is_file() else None for p in sorted(FILES)}
class Tee:
 def __init__(self,f,out):self.f,self.out=f,out
 def write(self,s):self.f.write(s);self.out.write(s);return len(s)
 def flush(self):self.f.flush();self.out.flush()
def main():
 parser=argparse.ArgumentParser();parser.add_argument('phase',choices=['import','parse','native']);parser.add_argument('--seal',type=Path,required=True);a=parser.parse_args()
 out=HERE/(a.phase+'-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S')+'-'+uuid.uuid4().hex[:8]);out.mkdir();print('Unique O2 registration evidence: '+str(out),flush=True)
 result={'phase':a.phase,'started':now(),'engine_started_via_dev':False,'validation_returned':False,'passed':False,'scope':SCOPE};code=2;start=time.monotonic()
 with (out/'raw.log').open('w') as raw:
  with contextlib.redirect_stdout(Tee(raw,sys.stdout)),contextlib.redirect_stderr(Tee(raw,sys.stderr)):
   try:
    seal_sha=sha(a.seal);seal=json.loads(a.seal.read_text());assert seal['sealed'] is True and seal['root']==str(ROOT);expected=seal['files'];assert set(expected)==FILES;missing={p for p,h in expected.items() if h is None};assert not missing or a.phase=='import' and missing=={TEST+'.uid'}
    before=observe();save(out/'sources-before-queue.json',before);assert before==expected,'Named sealed inputs drifted';save(out/'seal-used.json',seal)
    sys.dont_write_bytecode=True;spec=importlib.util.spec_from_file_location('cinder_o2_dev',ROOT/'scripts/dev/dev.py');dev=importlib.util.module_from_spec(spec);sys.modules[spec.name]=dev;spec.loader.exec_module(dev)
    env=dict(os.environ);env.pop(ENV,None);report_path=out/'native-report.json'
    if a.phase=='native':env[ENV]=str(report_path)
    context=dev.ProjectContext(root=ROOT,environ=env);cmd=[str(dev.resolve_godot(context)),'--path',str(ROOT),'--headless','--log-file',str(out/'engine.log')]
    cmd+=['--editor','--import'] if a.phase=='import' else ['--script','res://'+TEST]+(['--check-only'] if a.phase=='parse' else [])
    save(out/'command.json',{'argv':cmd,'cwd':str(ROOT),'timeout_after_queue_s':180,'report_env':{ENV:str(report_path)} if a.phase=='native' else {}});save(out/'queue.json',{'queued':now(),'lock':str(dev.shared_lock_path(ROOT)),'acquired':False})
    with dev.godot_lock(ROOT) as fd:
     save(out/'queue.json',{'acquired':now(),'lock':str(dev.shared_lock_path(ROOT))});at=observe();save(out/'sources-at-lock.json',at);assert at==expected and sha(a.seal)==seal_sha,'Queued named input/seal drift';save(out/'lifecycle.json',{'state':'RUNNING','at':now(),'custody':'Canonical dev owns/waits only its direct child; no foreign process/lock action'})
     result['engine_started_via_dev']=True;code=dev.run_validation(cmd,context,fd,180,detect_godot_errors=True);result.update(validation_returned=True,dev_return_code=code,owned_direct_child_wait_zero=code==0)
     after=observe();save(out/'sources-after-child.json',after);changed=[p for p,h in expected.items() if h is not None and after[p]!=h];added=[p for p,h in expected.items() if h is None and after[p] is not None];result['named_source_delta']={'changed':changed,'added':added};assert not changed and (a.phase=='import' and added==sorted(missing) or not added and not missing)
     if code==0 and a.phase=='native':
      r=json.loads(report_path.read_text());assert r['checks']==len(r['report']);assert r['failures']==sum(row['ok'] is False for row in r['report']);assert r['short_scope_complete'] is True and r['success'] is True and r['failures']==0 and r['first_failure']=={};assert r['source_before']==r['source_after']
      for path,pin in r['source_before'].items():
       if path=='fixture':assert pin['path']=='res://'+TEST and pin['sha256']==expected[TEST]
       else:assert pin['present'] is True and pin['sha256']==expected[path.removeprefix('res://')]
      initial=r['initial_closed_packet_disk'];assert initial['exact_story'].encode().__len__()==initial['story_bytes'] and hashlib.sha256(initial['exact_story'].encode()).hexdigest()==initial['story_sha256'];assert initial['exact_session'].encode().__len__()==initial['session_bytes'] and hashlib.sha256(initial['exact_session'].encode()).hexdigest()==initial['session_sha256']
      raw.flush();log=(out/'raw.log').read_text();assert 'Retained SHORT registration report: '+str(report_path)+' sha256='+sha(report_path) in log;assert f"A3-O2 SHORT canonical registration: {r['checks']} checks/0 failures, short_scope_complete=true" in log
      result['native']={'checks':r['checks'],'failures':0,'report_sha256':sha(report_path),'rows_footer_source_and_closed_packet_joins':True}
     result['passed']=code==0
   except Exception as e:print(type(e).__name__+': '+str(e));result['exception']=type(e).__name__+': '+str(e);code=code if code else 2
   finally:
    result.update(closed=True,closed_at=now(),runner_return_code=code,wall_s_including_queue=time.monotonic()-start);save(out/'result.json',result);save(out/'lifecycle.json',{'state':'CLOSED','engine_started_via_dev':result['engine_started_via_dev'],'validation_returned':result['validation_returned'],'code':code,'provenance':'Zero proves canonical child wait0; nonzero may be synthetic detectederror/timeout. No separate processgroup claim.'})
 save(out/'index.json',{'after_closed':True,'files':{p.name:{'sha256':sha(p),'bytes':p.stat().st_size} for p in sorted(out.iterdir()) if p.is_file()},'scope':SCOPE});print('O2 registration phase CLOSED code='+str(code),flush=True);return code
if __name__=='__main__':raise SystemExit(main())
