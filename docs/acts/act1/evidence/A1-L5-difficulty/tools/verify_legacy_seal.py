from pathlib import Path
import json,hashlib,struct,datetime
R=Path('/Users/howardchen/.codex/worktrees/campaign-act1/video game idea');D=Path('/private/tmp/a1-l5-difficulty-implementation');J=R/'.cinder/l5-difficulty/legacy-producer01'
def sha(b):return hashlib.sha256(b).hexdigest()
def dec(n):
 k=n[0]
 if k=='null':return None
 v=n[1]
 if k=='dictionary':return {a:dec(b) for a,b in v}
 if k=='array':return [dec(x) for x in v]
 if k=='float64':return struct.unpack('<d',bytes.fromhex(v))[0]
 if k=='integer':return int(v)
 if k in ['string','boolean']:return v
 raise ValueError(k)
def node(w):
 v=json.loads(w);assert v['api_revision']=='exact-json-1' and v['schema_version']==1;return v['value']
def at(n,*keys):
 for key in keys:
  assert n[0]=='dictionary';n=dict(n[1])[key]
 return n
v=json.loads((J/'native.json').read_text());receipt=json.loads((J/'receipt.json').read_text())
assert sha((J/'native.json').read_bytes())=='b0f68e2359f7703e0115f58dbf22bdfa397db6769e305a4ad9711e29993ac380'
assert receipt['result']=='passed' and receipt['exit_code']==0 and not receipt['raw_error_warning_lines'] and not receipt['selected_input_changes']
assert v['case']=='legacy-producer' and v['checks']==168 and v['failures']==0 and v['success'] and v['complete'] and v['first_failure']=={}
assert len(v['assertions'])==168 and all(a['passed'] is True for a in v['assertions'])
order=['entry','cp2','cp3','first-final-blink'];assert v['branch_order']==order
summaries={};companions=0;previous_clock=-1
for label,hp,hits,cp in [('entry',240.,0,''),('cp2',160.,4,'moon-phase-2'),('cp3',80.,8,'moon-phase-3'),('first-final-blink',80.,8,'moon-phase-3')]:
 b=v['branches'][label];current=node(b['current_exact']);checkpoint=node(b['checkpoint_exact']);attempts=node(b['attempts_exact'])
 for name in ['current','checkpoint','attempts']:assert sha(b[name+'_exact'].encode())==b[name+'_sha256']
 assert at(attempts,'story','snapshot')==current and at(attempts,'story','checkpoint')==checkpoint
 for n in [current,checkpoint]:
  u=dec(n);local=u['level']['local']
  assert len(local)==16 and local['api_revision']=='act1-living-moon-level-1' and type(local['schema_version']) is int and local['schema_version']==1 and 'final_arrangement' not in local
  assert u['level']['local_snapshot_version']==1 and local['world_revision']==1 and local['scheduler']['schema_version']==4 and local['eye']['schema_version']==2
  assert local['scheduler']['profile']['id']=='challenge' and u['shell']['difficulty_at_entry']=='challenge' and local['eye']['hp']==hp
  assert u['level']['progress']['checkpoint_id']==cp
 assert b['primary_count']==hits
 decoded=dec(current);clock=decoded['level']['local']['scheduler']['clock_s'];assert clock>=previous_clock;previous_clock=clock
 if label in ['cp2','cp3']:assert current==checkpoint
 if label in ['cp3','first-final-blink']:assert decoded['level']['local']['sneeze_demonstrated'] is True
 assert dec(attempts)['completed_main']==['A1-L1','A1-L2','A1-L3','A1-L4']
 assert b['raw_store']==b['all_original_disk_files']['campaign.json']
 for name,row in b['all_original_disk_files'].items():
  path=R/row['path'][6:] if row['path'].startswith('res://') else Path(row['path'])
  raw=path.read_bytes();assert len(raw)==row['bytes'] and sha(raw)==row['sha256'] and raw==bytes.fromhex(row['hex']);companions+=1
  if name=='campaign.json':
   e=json.loads(raw);assert e['format_version']==2 and e['payload_json']==b['attempts_exact'] and e['sha256']==b['attempts_sha256']
 rawpath=R/b['raw_store']['path'][6:];assert json.loads((rawpath.parent/'branch.json').read_text())==b
 summaries[label]={'hp':hp,'primary_count':hits,'clock_s':clock,'current_sha256':b['current_sha256'],'checkpoint_sha256':b['checkpoint_sha256'],'attempts_sha256':b['attempts_sha256'],'raw_store_sha256':b['raw_store']['sha256'],'raw_store_bytes':b['raw_store']['bytes'],'generation':b['generation']}
assert v['branches']['first-final-blink']['checkpoint_exact']==v['branches']['cp3']['checkpoint_exact']
assert v['branches']['cp2']['attempts_exact']!=v['branches']['cp3']['attempts_exact']
assert len(v['primary_receipts'])==8
for i,p in enumerate(v['primary_receipts']):assert p['before_hp']==240.-i*20. and p['after_hp']==220.-i*20. and p['action']['kind']=='primary' and p['action']['origin']=='player_direct' and p['action']['hits']==1
assert v['hp_boundaries']==[240.,160.,80.] and len(v['phase_observers'])==2
assert any(a['passed'] is True and a['label'].startswith('producer stops after original eight primaries/two checkpoints/first final Save; no defeat or exit claim') for a in v['assertions'])
last=dec(node(v['branches']['first-final-blink']['current_exact']))
assert last['level']['local']['stage']=='final' and last['level']['local']['eye']['hp']==80. and last['level']['progress']['completed'] is False and last['level']['progress']['contact_exit_id']==''
first=v['first_final_admission'];assert first['source_ids']==['moon-eye'] and first['preselection']['pure']
assert dec(node(v['branches']['first-final-blink']['current_exact']))['level']['local']['blink']['phase']=='warning'
state=json.loads((D/'STATE.json').read_text())
for n,h in state['source_hashes'].items():assert sha((R/n).read_bytes())==h
assert not (R/'data/campaign/act1/a1_l5_difficulty_arrangements.json').exists()
pre=json.loads((J/'source-pre.json').read_text())['files'];post=json.loads((J/'source-post.json').read_text())['files'];assert pre==post
copies=0
for bank,rows in [('source-pre',pre),('source-post',post)]:
 for row in rows:
  if not row['exists']:continue
  raw=(J/bank/row['bank_path']).read_bytes();assert len(raw)==row['bytes'] and sha(raw)==row['sha256'];copies+=1
out={'created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'verified':True,'scope':'Actual current old-Challenge writer sealed before reader promotion. Same producer genuine whole CP2 captured after4 ordinary hits before CP3 after8; first final Blink Save retains CP3. TEST predecessor prefix, public Rusher injury and supported Hero setup disclosed. No native full route or changed response credit.','native_sha256':sha((J/'native.json').read_bytes()),'native_checks':168,'native_failures':0,'all_assertion_rows_passed':168,'source_bank_copies_verified':copies,'original_companion_files_verified':companions,'branches':summaries,'first_final_preselection':{'both_eligible':first['preselection']['both_eligible'],'blink_reason':first['preselection']['blink']['reason'],'nose_reason':first['preselection']['nose']['reason'],'nose_cooldown_ready_s':first['boundary']['nose_control']['cooldown']['ready_s'],'clock_s':first['clock_s'],'scope':'Nose naturally cooldown-ineligible on original first Blink tick; no both-eligible or clock-identity claim. Preserve cooldown on new trial.'},'old_writer_still_installed':True,'new_recipe_absent':True,'uid':(R/'tests/acts/act1/a1_l5_difficulty.gd.uid').read_text().strip()}
(D/'legacy-producer01-seal-verification.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
