from pathlib import Path
import json,subprocess,hashlib,os,datetime,uuid
root=Path.cwd();plan=json.loads((root/'.cinder/a2-l5-integration-copy-plan.json').read_text());assert subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()==plan['base'];assert not subprocess.check_output(['git','status','--porcelain'])
changes=sorted(plan['changes'],key=lambda r:(not r['path'].endswith('/.gdignore'),r['path']));child=subprocess.Popen(['git','cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE);rows=[];started=datetime.datetime.now(datetime.timezone.utc).isoformat()
for index,row in enumerate(changes,1):
 child.stdin.write((row['blob']+'\n').encode());child.stdin.flush();h=child.stdout.readline().decode().split();assert h[0]==row['blob'] and h[1]=='blob';b=child.stdout.read(int(h[2]));assert child.stdout.read(1)==b'\n';assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==row['blob']
 p=root/row['path'];p.parent.mkdir(parents=True,exist_ok=True);q=p.with_name(p.name+'.'+str(uuid.uuid4())+'.integrationtmp');q.write_bytes(b);os.chmod(q,0o755 if row['mode']=='100755' else 0o644);os.replace(q,p);actual=p.read_bytes();assert actual==b
 rows.append({**row,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
 if index%1000==0:print(f'Copied and verified {index}/{len(changes)} exact Act2-owned delta rows.',flush=True)
child.stdin.close();assert child.wait()==0
receipt={'started_at':started,'closed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate':plan['candidate'],'integration_base':plan['base'],'handoff':plan['handoff'],'rows':rows,'total_bytes':sum(r['bytes'] for r in rows),'scope':'Exact candidate scopedcopy, .gdignore boundaries installed before originals. No otheract/shared/settings/ledger copies, no registry or acceptance changes, no engine/native credit.'};p=root/'.cinder/a2-l5-integration-copy-receipt.json';p.write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({'rows':len(rows),'bytes':receipt['total_bytes'],'candidate':plan['candidate'],'receipt_sha256':hashlib.sha256(p.read_bytes()).hexdigest()}))
