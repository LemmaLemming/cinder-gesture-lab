from pathlib import Path
import datetime,json,subprocess,sys,uuid
here=Path(__file__).resolve().parent;root=here.parents[1]
cases=[('standard','trunk','neutral'),('assisted','trunk','neutral')]+[('challenge',court,kit) for kit in ['short','weak','slow'] for court in ['trunk','priority']]
record=here/('focused-controls-'+uuid.uuid4().hex[:8]+'.json');rows=[]
for index,(profile,court,kit) in enumerate(cases):
 cmd=['python3',str(here/'run.py'),'run','--test','native','--seal',str(here/'seal-natural-sun-cases.json'),'--','--profile='+profile,'--court='+court,'--kit='+kit]
 row={'index':index,'profile':profile,'court':court,'kit':kit,'command':cmd,'started':datetime.datetime.now(datetime.timezone.utc).isoformat(),'state':'RUNNING'};rows.append(row);record.write_text(json.dumps({'cases':rows,'remaining_unexecuted':cases[index+1:],'all_complete':False},indent=2)+'\n');print('FOCUSED_CASE',profile,court,kit,flush=True)
 result=subprocess.run(cmd,cwd=root);row.update(state='CLOSED',return_code=result.returncode,closed_at=datetime.datetime.now(datetime.timezone.utc).isoformat());record.write_text(json.dumps({'cases':rows,'remaining_unexecuted':cases[index+1:],'all_complete':index==len(cases)-1 and result.returncode==0},indent=2)+'\n')
 if result.returncode:print('Stopped at concrete failed targeted case; later cases unexecuted:',record,flush=True);raise SystemExit(result.returncode)
print('FOCUSED_CONTROLS_COMPLETE',record,flush=True)
