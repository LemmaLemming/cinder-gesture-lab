#!/usr/bin/env python3
"""Read ONE already closed fresh L5 producer. No engine, polling, Git or source writes.
Adapted from verify_legacy_seal.py; original verifier/evidence stay untouched.
Only the explicitly selected private JSON output is created, never overwritten.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, re, struct

DEFAULT_ROOT = Path('/Users/howardchen/.codex/worktrees/campaign-act1/video game idea')
PRIVATE_ROOT = Path('/private/tmp/a1-l5-difficulty-implementation')
EXPECTED_PINS = {
    'scripts/acts/act1/living_moon.gd': '89dc49fe6e37c05679d1f4592c9873f01f1c4ea92720d2ec0209624985be7e7f',
    'scripts/acts/act1/living_moon_codec.gd': '25bca033d4ce0e1f04abdeb08fb1645887e72246bb978ee7d1d5ae46a4ba73b9',
    'data/campaign/act1/a1_l5_difficulty_arrangements.json': '06b65a15b5f56791291d2614346b0973be0d09f91c2466dad8f0ecf20f4463c9',
    'tests/acts/act1/a1_l5_difficulty.gd': 'a68ae47054c367f2329a807edd24a8431de34baa1eebf840c49933128e6241ef',
}
LEGACY_KEYS = {'api_revision','schema_version','world_revision','stage','impact_demonstrated','sneeze_demonstrated','next_attack','pending_phase','escape','actors','eye','scheduler','impact','nose','blink','framing'}
DESCRIPTOR = {'profile_id':'challenge','recipe_id':'A1-L5/final-sneeze-leads@v1','initial_attack':'sneeze'}
ORDER = ['entry','cp2','cp3','first-final-sneeze']

def sha(data): return hashlib.sha256(data).hexdigest()
def require(ok, label):
    if not ok: raise ValueError(label)
def dec(n):
    require(isinstance(n,list) and n, 'exact node must be a nonempty array')
    kind=n[0]
    if kind=='null': require(len(n)==1,'closed null node'); return None
    require(len(n)==2,'closed typed node'); value=n[1]
    if kind=='dictionary':
        require(isinstance(value,list) and all(isinstance(x,list) and len(x)==2 and isinstance(x[0],str) for x in value),'dictionary node entries')
        require(len({x[0] for x in value})==len(value),'unique dictionary keys')
        return {a:dec(b) for a,b in value}
    if kind=='array': return [dec(x) for x in value]
    if kind=='float64':
        require(isinstance(value,str) and re.fullmatch('[0-9a-f]{16}',value) is not None,'literal float64 bits')
        return struct.unpack('<d',bytes.fromhex(value))[0]
    if kind=='integer': require(isinstance(value,str) and str(int(value))==value,'literal integer type'); return int(value)
    if kind=='string': require(isinstance(value,str),'string node type'); return value
    if kind=='boolean': require(type(value) is bool,'boolean node type'); return value
    raise ValueError('unsupported exact node kind '+str(kind))
def node(wire):
    envelope=json.loads(wire)
    require(set(envelope)=={'api_revision','schema_version','value'} and envelope['api_revision']=='exact-json-1' and envelope['schema_version']==1,'exact-json-1 envelope')
    dec(envelope['value'])
    return envelope['value']
def at(n,*keys):
    for key in keys:
        require(n[0]=='dictionary','exact join requires dictionary'); n=dict(n[1])[key]
    return n
def resolve(root,value): return (root/(value[6:] if value.startswith('res://') else value)).resolve()
def safe_part(value): return isinstance(value,str) and value not in ('','.','..') and '/' not in value and '\\' not in value

def verify(args):
    root=args.root.resolve(); run=resolve(root,args.run_dir)
    require(run.is_relative_to(root/'.cinder/l5-difficulty') and run!=root/'.cinder/l5-difficulty','explicit scoped run required')
    # Closure first. Do not read a native result while the run is still open.
    receipt=json.loads((run/'receipt.json').read_bytes())
    require(receipt.get('state')=='closed' and receipt.get('closed_at') and receipt.get('subprocess_started') is True,'run must already be closed after actual process execution')
    require(receipt.get('result')=='passed' and receipt.get('exit_code')==0 and receipt.get('raw_error_warning_lines')==[] and receipt.get('selected_input_changes')==[] and receipt.get('selected_input_changes_at_banner')==[] and receipt.get('interrupt_forwarded') is False,'actual closed clean passed exit and frozen selected inputs required')
    data=(run/'native.json').read_bytes(); require(sha(data)==args.native_sha256==receipt.get('native_report_sha256'),'exact caller-pinned native SHA')
    require(Path(receipt['native_report_original']).read_bytes()==data,'original native bytes equal bank')
    v=json.loads(data); count=args.expected_checks
    require(v.get('case')=='fresh-producer' and v.get('checks')==count and v.get('failures')==0 and v.get('success') is True and v.get('complete') is True and v.get('first_failure')=={},'fresh native case/count/success/completion')
    rows=v.get('assertions'); require(isinstance(rows,list) and len(rows)==count and all(a.get('passed') is True and a.get('index')==i+1 and isinstance(a.get('label'),str) and a['label'] for i,a in enumerate(rows)),'every actual assertion row agrees')
    require(receipt.get('footer_count')==1 and receipt.get('footer_report_counts_agree') is True and receipt.get('footer_report_identity_agrees') is True and receipt.get('requested_case')=='fresh-producer','unique footer identity agrees')
    raw=(run/'raw.log').read_bytes(); require(sha(raw)==receipt['raw_sha256'],'original raw hash')
    require(not re.search(rb'(?im)^.*(?:SCRIPT ERROR|ERROR:|WARNING:)',raw),'raw diagnostics must be clean')
    footers=re.findall(rb'A1-L5 DIFFICULTY: (\d+) checks, (\d+) failures; complete=(true|false); report=(\S+)',raw)
    require(len(footers)==1 and footers[0][:3]==(str(count).encode(),b'0',b'true') and resolve(root,footers[0][3].decode())==Path(receipt['native_report_original']).resolve(),'literal raw footer independently matches output')
    require(v.get('branch_order')==ORDER and set(v.get('branches',{}))==set(ORDER),'exact same-producer four branch order')
    summaries={}; companions=[]; previous_clock=-1.; previous_generation=-1; current_nodes={}; decoded_units={}
    artifact=resolve(root,v['artifact_root']); require(artifact.is_relative_to(root/'.cinder') and artifact!=root/'.cinder','original artifact root scoped')
    for label,hp,hits,cp,stage in [('entry',240.,0,'','return'),('cp2',160.,4,'moon-phase-2','sneeze'),('cp3',80.,8,'moon-phase-3','final'),('first-final-sneeze',80.,8,'moon-phase-3','final')]:
        b=v['branches'][label]; current=node(b['current_exact']); checkpoint=node(b['checkpoint_exact']); attempts=node(b['attempts_exact'])
        current_nodes[label]=(current,checkpoint); decoded_units[label]=dec(current)
        for name in ['current','checkpoint','attempts']: require(sha(b[name+'_exact'].encode())==b[name+'_sha256'],label+' exact '+name+' hash')
        require(at(attempts,'story','snapshot')==current and at(attempts,'story','checkpoint')==checkpoint,label+' full exact tagged Attempts joins')
        for n in [current,checkpoint]:
            u=dec(n); local=u['level']['local']
            require(set(local)==LEGACY_KEYS|{'final_arrangement'} and local['api_revision']=='act1-living-moon-level-2' and type(local['schema_version']) is int and local['schema_version']==2 and local['final_arrangement']==DESCRIPTOR,label+' literal new17/API2/descriptor')
            require(u['level']['local_snapshot_version']==1 and type(local['world_revision']) is int and local['world_revision']==1 and local['scheduler']['schema_version']==4 and local['eye']['schema_version']==2,label+' unchanged outer/world/native schemas')
            require(local['scheduler']['profile']['id']=='challenge' and u['shell']['difficulty_at_entry']=='challenge' and local['eye']['hp']==hp and local['stage']==stage,label+' actual native/Shell profile HP/stage')
            require(u['level']['progress']['checkpoint_id']==cp,label+' original checkpoint ID')
        require(b['primary_count']==hits and b['local_schema']==2 and b['profile_id']=='challenge' and b['label']==label,label+' branch counts/schema/profile')
        clock=dec(current)['level']['local']['scheduler']['clock_s']
        require(clock>previous_clock and b['generation']>previous_generation,label+' monotone actual clock/generation');previous_clock=clock;previous_generation=b['generation']
        if label in ['cp2','cp3']: require(current==checkpoint,label+' exact native current equals just-published checkpoint')
        if label in ['cp3','first-final-sneeze']: require(dec(current)['level']['local']['sneeze_demonstrated'] is True,label+' genuine retained Sneeze demonstration')
        attempt=dec(attempts); require(attempt['completed_main']==['A1-L1','A1-L2','A1-L3','A1-L4'] and attempt['side_attempt'] is None,label+' disclosed TEST prefix/no side attempt')
        require(b['raw_store']==b['all_original_disk_files']['campaign.json'],label+' raw_store alias')
        for name,row in b['all_original_disk_files'].items():
            require(safe_part(name),'safe companion member'); original=resolve(root,row['path']);require(original==artifact/label/name,'original companion artifact identity')
            content=original.read_bytes();require(len(content)==row['bytes'] and sha(content)==row['sha256'] and content.hex()==row['hex'],label+'/'+name+' original bytes/SHA/hex')
            companions.append({'original_path':str(original),'bytes':len(content),'sha256':sha(content),'branch':label,'name':name})
            if name=='campaign.json':
                e=json.loads(content);require(e['format_version']==2 and e['payload_json']==b['attempts_exact'] and e['sha256']==b['attempts_sha256'] and e['generation']==b['generation'],label+' original whole Store exact payload/generation')
        branch_path=artifact/label/'branch.json';require(json.loads(branch_path.read_bytes())==b,label+' original branch.json literal row')
        companions.append({'original_path':str(branch_path),'bytes':branch_path.stat().st_size,'sha256':sha(branch_path.read_bytes()),'branch':label,'name':'branch.json'})
        summaries[label]={'hp':hp,'primary_count':hits,'clock_s':clock,'local_schema':2,'final_arrangement':DESCRIPTOR,'current_sha256':b['current_sha256'],'checkpoint_sha256':b['checkpoint_sha256'],'attempts_sha256':b['attempts_sha256'],'raw_store_sha256':b['raw_store']['sha256'],'generation':b['generation']}
    require(current_nodes['first-final-sneeze'][1]==current_nodes['cp3'][1] and current_nodes['cp2'][1]!=current_nodes['cp3'][1],'final branch retains exact original CP3; CP2 remains independent')
    require(len(v['primary_receipts'])==8,'exact eight primary receipts')
    for i,p in enumerate(v['primary_receipts']):
        action=p['action']; require(p['before_hp']==240.-i*20. and p['after_hp']==220.-i*20. and action['kind']=='primary' and action['origin']=='player_direct' and action['hits']==1 and action['damage']==20.,'real ordinary20 primary '+str(i+1))
        require(any(s['armed'] is True and s['state']=='recovery' and s['active_until_s']<p['clock_s']<s['recovery_until_s'] and s['opening_position']==[0.,0.,-9.] for s in p['sources']),'primary within actual native recovery '+str(i+1))
    require(v['hp_boundaries']==[240.,160.,80.] and [(p['phase'],p['hp']) for p in v['phase_observers']]==[(2,160.),(3,80.)],'genuine exact phase observers')
    require(summaries['cp2']['clock_s']<v['primary_receipts'][4]['clock_s'] and [x['primary_count'] for x in v['checkpoint_pause_requests']]==[4,8],'same producer CP2 archived after4 before fifth hit')
    last=decoded_units['first-final-sneeze'];local=last['level']['local'];first=v['first_final_admission']
    require(local['eye']['hp']==80. and last['level']['progress']['completed'] is False and last['level']['progress']['contact_exit_id']=='','producer stops before boss defeat/exit')
    require(first['source_ids']==['moon-nose'] and first['preselection']['pure'] is True and first['preselection']['clock_s']==first['clock_s'] and summaries['cp3']['clock_s']<first['clock_s'],'first genuine Sneeze after independent CP3 and pure same-tick preselection')
    require(local['nose']['status']=='running' and local['nose']['phase'] in ['warning','lock'] and local['blink']['status']!='running' and local['next_attack']=='blink' and len(local['scheduler']['reservations'])==1 and local['scheduler']['reservations'][0]['source_id']=='moon-nose','saved first final Sneeze before Blink follower')
    require(v['source_pre']==v['source_post'],'native source pins unchanged')
    pre_data=(run/'source-pre.json').read_bytes();post_data=(run/'source-post.json').read_bytes()
    require(sha(pre_data)==receipt['source_pre_manifest_sha256'] and sha(post_data)==receipt['source_post_manifest_sha256'] and pre_data==post_data,'recorded exact pre/post manifests equal')
    pre=json.loads(pre_data)['files'];selected={row['bank_path']:row for row in pre};copies=0
    for bank in ['source-pre','source-post']:
        for row in pre:
            path=Path(row['bank_path']);require(not path.is_absolute() and '..' not in path.parts,'safe selected bank path')
            file=run/bank/path
            if not row['exists']: require(not file.exists(),'original absent bank member stays absent');continue
            content=file.read_bytes();require(len(content)==row['bytes'] and sha(content)==row['sha256'],'original bank hash '+str(file));copies+=1
    for name,digest in EXPECTED_PINS.items():
        require(selected[name]['exists'] and selected[name]['sha256']==digest and sha((root/name).read_bytes())==digest,'sealed/current exact promoted input '+name)
    for name in list(EXPECTED_PINS)[:3]: require(v['source_pre']['res://'+name]==EXPECTED_PINS[name],'native recorded runtime/recipe SHA '+name)
    uid_name='tests/acts/act1/a1_l5_difficulty.gd.uid'; require(selected[uid_name]['exists'] and sha((root/uid_name).read_bytes())==selected[uid_name]['sha256'],'actual unchanged fixture UID present')
    git={}
    for name in ['git_before','git_at_native_banner','git_after']:
        info=receipt[name];require(info['revision'].startswith(args.expected_revision) and info['branch']=='codex/campaign-act1' and info['selected_status']==[],'recorded owner/clean scoped Git '+name)
        git[name]={key:info[key] for key in ['revision','branch','selected_status']}
    return {'created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'verified':True,'scope':'One closed genuine new17 Challenge producer; exact tagged whole-unit joins, original companion custody and selected source banks only. No new native validator execution or engine work. TEST predecessor prefix/Rusher injury/supported Hero placements preserved; no final altered-response novelty or full-route claim.','native_sha256':sha(data),'receipt_sha256':sha((run/'receipt.json').read_bytes()),'native_checks':count,'native_failures':0,'all_assertion_rows_passed':count,'source_bank_copies_verified':copies,'source_count':len(pre),'original_companion_files_verified':len(companions),'companions':companions,'branches':summaries,'source_pins':EXPECTED_PINS,'git':git,'first_final_preselection':{'clock_s':first['clock_s'],'both_eligible':first['preselection']['both_eligible'],'blink_preview':{k:first['preselection']['blink'].get(k) for k in ['accepted','reason']},'nose_preview':{k:first['preselection']['nose'].get(k) for k in ['accepted','reason']},'source_control_cooldowns':{name:first['boundary'][name].get('cooldown') for name in ['eye_control','nose_control']},'scope':'Actual new-run preselection retained literally; no old/new equal-clock, simultaneous-eligibility or novelty inference.'},'uid':(root/uid_name).read_text().strip()}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=DEFAULT_ROOT)
    p.add_argument('--run-dir',required=True)
    p.add_argument('--native-sha256',required=True)
    p.add_argument('--expected-checks',required=True,type=int)
    p.add_argument('--expected-revision',default='2ea6a0a5')
    p.add_argument('--output-json',required=True,type=Path)
    args=p.parse_args();require(re.fullmatch('[0-9a-f]{64}',args.native_sha256) and args.expected_checks>0,'caller must supply actual closed native SHA/count')
    require(re.fullmatch('[0-9a-f]{8,40}',args.expected_revision),'explicit revision prefix')
    output=args.output_json.resolve();require(output.is_relative_to(PRIVATE_ROOT) and not output.exists(),'new private output path required, no overwrites')
    result=verify(args)
    with output.open('x') as f:json.dump(result,f,indent=2);f.write('\n')
    print(json.dumps({'verified':True,'output':str(output),'sha256':sha(output.read_bytes()),'native_checks':result['native_checks'],'source_bank_copies_verified':result['source_bank_copies_verified'],'companions_verified':result['original_companion_files_verified']}))

if __name__=='__main__':
    try:main()
    except (OSError,ValueError,KeyError,TypeError,AssertionError) as exc:
        raise SystemExit('Fresh producer seal verification stopped: '+str(exc))
