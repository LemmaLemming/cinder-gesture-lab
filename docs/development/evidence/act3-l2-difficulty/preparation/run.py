from pathlib import Path
import argparse,contextlib,datetime,hashlib,importlib.util,json,os,subprocess,sys,time,uuid
ROOT=Path.cwd();HERE=Path(__file__).resolve().parent
SCRIPTS={'pure':'tests/act3_l2_arrangement_pure.gd','legacy':'tests/act3_l2_arrangement_legacy.gd','native':'tests/act3_l2_arrangement_native.gd','shell':'tests/act3_l2_arrangement_shell.gd'}
NAMES=['scripts/acts/act3/living_forest_level.gd','scripts/acts/act3/living_forest.gd','scripts/acts/act3/living_forest_scenery.gd','data/campaign/act3/a3_l2_encounters.json','scenes/acts/act3/a3_l2_living_forest.tscn','scripts/acts/act3/root_latcher.gd','scripts/acts/act3/root_latcher_art.gd','scripts/acts/act3/sunbound_stalker.gd','scripts/combat/encounter_arrangement.gd','scripts/combat/difficulty.gd','scripts/combat/threat_scheduler.gd','scripts/combat/threat_geometry.gd','scripts/combat/body_sweep.gd','scripts/combat/lane_mechanism.gd','scripts/cues/interaction_cue.gd','scripts/campaign/shell.gd','scripts/campaign/level.gd','scripts/campaign/registry.gd','scripts/campaign/attempts.gd','scripts/campaign/save_store.gd','scripts/campaign/exact_json.gd','scripts/campaign/snapshot_codec.gd','scripts/player.gd','scripts/game.gd','scripts/hud.gd','scripts/ui/campaign_menu.gd','scripts/equipment.gd','data/design/player_equipment.json','data/campaign/registry.json','scenes/main.tscn','project.godot','scripts/dev/dev.py','tests/acts/act3/living_forest_route_smoke.gd','tests/acts/act3/pillars_before_time_optional_shell.gd',*SCRIPTS.values(),str(Path(__file__).resolve().relative_to(ROOT))]
FIXTURE='tests/acts/act3/fixtures/a3_l2_difficulty_legacy/'
NAMES += [FIXTURE+profile+'-'+stage+suffix for profile in ['standard','challenge'] for stage in ['entrance','root-warning'] for suffix in ['.exact.json','.store.json']]+[FIXTURE+'PROVENANCE.json']
FILES=set(NAMES)|{p+'.uid' for p in NAMES if p.endswith('.gd')}
ENV={'pure':'CINDER_FOREST_PURE_REPORT','legacy':'','native':'CINDER_FOREST_ARRANGEMENT_OUTPUT','shell':'CINDER_FOREST_SHELL_REPORT'}
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_text(json.dumps(d,indent=2)+'\n')
def observe():return {p:sha(ROOT/p) if (ROOT/p).is_file() else None for p in sorted(FILES)}
class Tee:
 def __init__(self,f,out):self.f,self.out=f,out
 def write(self,s):self.f.write(s);self.out.write(s);return len(s)
 def flush(self):self.f.flush();self.out.flush()
def main():
 a=argparse.ArgumentParser();a.add_argument('phase',choices=['seal','import','parse','run']);a.add_argument('--test',choices=SCRIPTS,default='native');a.add_argument('--seal',type=Path);a.add_argument('--portrait',action='store_true');a.add_argument('args',nargs='*');q=a.parse_args()
 if q.phase=='seal':
  save(q.seal or HERE/'seal.json',{'root':str(ROOT),'files':observe(),'scope':'Fixed named changed-level and directly affected files/UIDs and8literalfixtures, not dependency/global/UID census'});print('Sealed',len(FILES),'named inputs');return 0
 seal=json.loads(q.seal.read_text());expected=seal['files'];assert set(expected)==FILES
 folder=HERE/(q.phase+'-'+q.test+'-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S')+'-'+uuid.uuid4().hex[:8]);folder.mkdir();print('FOREST_EVIDENCE',folder,flush=True)
 result={'started':now(),'phase':q.phase,'test':q.test,'engine_started':False,'returned':False};code=2;start=time.monotonic()
 with (folder/'raw.log').open('w') as f,contextlib.redirect_stdout(Tee(f,sys.stdout)),contextlib.redirect_stderr(Tee(f,sys.stderr)):
  try:
   missing={p for p,h in expected.items() if h is None};allowed={p+'.uid' for p in SCRIPTS.values()};assert not missing or q.phase=='import' and missing<=allowed,missing
   before=observe();save(folder/'sources-before-queue.json',before);assert before==expected,'sealed source drift';save(folder/'seal-used.json',seal)
   sys.dont_write_bytecode=True;spec=importlib.util.spec_from_file_location('cinder_forest_dev',ROOT/'scripts/dev/dev.py');dev=importlib.util.module_from_spec(spec);sys.modules[spec.name]=dev;spec.loader.exec_module(dev)
   env=dict(os.environ);report=folder/'native-report.json'
   for key in ['CINDER_FOREST_PURE_REPORT','CINDER_FOREST_ARRANGEMENT_OUTPUT','CINDER_FOREST_SHELL_REPORT','CINDER_FOREST_ARRANGEMENT_PORTRAITS']:env.pop(key,None)
   if q.phase=='run' and ENV[q.test]:env[ENV[q.test]]=str(report)
   env['CINDER_FOREST_ARRANGEMENT_SOURCES']=json.dumps(sorted(FILES))
   if q.portrait:
    portraits=folder/'portraits';portraits.mkdir();env['CINDER_FOREST_ARRANGEMENT_PORTRAITS']=str(portraits)
   context=dev.ProjectContext(root=ROOT,environ=env);cmd=[str(dev.resolve_godot(context)),'--path',str(ROOT),'--log-file',str(folder/'engine.log')]
   if not q.portrait:cmd+=['--headless']
   if q.phase=='import':cmd+=['--editor','--import']
   else:
    cmd+=['--script','res://'+SCRIPTS[q.test]]
    if q.phase=='parse':cmd+=['--check-only']
    if q.phase=='run':
     args=q.args[:]
     if q.test=='legacy':args+=['--report='+str(report)]
     if args:cmd+=['--',*args]
   save(folder/'command.json',{'argv':cmd,'cwd':str(ROOT),'env':{k:v for k,v in env.items() if k.startswith('CINDER_FOREST')},'timeout_after_queue_s':180});save(folder/'queue.json',{'queued':now(),'acquired':False,'lock':str(dev.shared_lock_path(ROOT))})
   with dev.godot_lock(ROOT) as fd:
    save(folder/'queue.json',{'acquired':now(),'lock':str(dev.shared_lock_path(ROOT))});at=observe();save(folder/'sources-at-lock.json',at);assert at==expected,'queued source drift'
    save(folder/'lifecycle.json',{'state':'RUNNING','at':now(),'custody':'dev owns/waits its direct child only; no foreign kill/lock operation'})
    result['engine_started']=True;code=dev.run_validation(cmd,context,fd,180,detect_godot_errors=True);result.update(returned=True,dev_return_code=code)
    after=observe();save(folder/'sources-after-child.json',after);changed=[p for p,h in expected.items() if h is not None and h!=after[p]];added=[p for p in missing if after[p] is not None];result['delta']={'changed':changed,'added':sorted(added)};assert not changed and (q.phase=='import' and set(added)==missing or not missing and not added)
    if q.phase=='run' and code==0:
     d=json.loads(report.read_text());rows=d.get('rows',d.get('report',[]));assert d['checks']==len(rows) and d['failures']==0 and d['complete'] and d['success'] and d['first_failure']=={} and all(x['ok'] for x in rows)
     if 'source_before' in d:assert d['source_before']==d['source_after']
     if q.portrait:assert d.get('captures') and all(v['unchanged_native_pair'] and v['dimensions']==[540,1170] for v in d['captures'].values()),'Requested portrait captures missing/unstable'
     result['native']={'checks':d['checks'],'failures':d['failures'],'report_sha256':sha(report),'complete':d['complete'],'actual_true_rows':len(rows)}
    result['passed']=code==0
  except Exception as e:print(type(e).__name__+': '+str(e));result['exception']=type(e).__name__+': '+str(e);code=code or 2
  finally:
   result.update(closed=True,closed_at=now(),runner_return_code=code,wall_s_including_queue=time.monotonic()-start);save(folder/'result.json',result);save(folder/'lifecycle.json',{'state':'CLOSED','engine_started':result['engine_started'],'validation_returned':result['returned'],'code':code,'custody':'0 confirms canonical direct child waited0; nonzero may be detectederror/timeout; no processgroup claim'})
 save(folder/'index.json',{'after_closed':True,'files':{p.name:{'sha256':sha(p),'bytes':p.stat().st_size} for p in folder.iterdir() if p.is_file()}});print('FOREST_PHASE_CLOSED',code,flush=True);return code
if __name__=='__main__':raise SystemExit(main())
