from pathlib import Path
import re,json,hashlib,stat,subprocess,datetime
root=Path.cwd();plan=root/'.cinder/spore-shared-validation-review/STORAGE_RECOVERY_PLAN.md';raw=plan.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='424c69d3e65830fbead702b326d9dac0acbb80bf9864d2f44dc77dae72e67284'
section=raw.decode().split('## Root-only priority supplement')[1]
groups={}
for key,suffix,size,sha,source in re.findall(r'- \*\*(R\d+)\*\* suffix `([^`]+)`; ([\d,]+) bytes; SHA `([0-9a-f]+)`\. Retain `([^`]+)`',section):
 groups[key]={'suffix':suffix,'bytes':int(size.replace(',','')),'sha256':sha,'source':source}
assert len(groups)==12
banks=[]
for bank,keys,receipt,sha in re.findall(r'\| `([^`]+)` \| ([^|]+) \| `([^`]+)` \(SHA `([0-9a-f]+)`\)',section):
 p=Path(receipt);assert hashlib.sha256(p.read_bytes()).hexdigest()==sha
 banks.append({'bank':bank,'groups':keys.strip(),'receipt':receipt,'sha256':sha})
assert len(banks)==23
rows=[]
def meta(p,expected):
 s=p.lstat();assert stat.S_ISREG(s.st_mode) and not p.is_symlink() and s.st_nlink==1 and s.st_flags==0
 assert p.is_relative_to(root/'.cinder')
 assert s.st_size==expected['bytes'] and hashlib.sha256(p.read_bytes()).hexdigest()==expected['sha256']
 return {'path':str(p),'bytes':s.st_size,'sha256':expected['sha256'],'mode':stat.S_IMODE(s.st_mode),'mtime_ns':s.st_mtime_ns,'atime_ns':s.st_atime_ns,'inode':s.st_ino,'device':s.st_dev,'uid':s.st_uid,'gid':s.st_gid,'blocks':s.st_blocks}
for k,g in groups.items():
 g['original']=meta(Path(g['source']),g)
for b in banks:
 if b['groups']=='retained only':continue
 for k in b['groups'].split(','):
  g=groups[k];p=Path(b['bank'])/g['suffix'];r=meta(p,g);assert r['device']==g['original']['device'] and r['inode']!=g['original']['inode'];r.update({'group':k,'source':g['source']});rows.append(r)
assert len(rows)==264
out={'created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'plan_sha256':hashlib.sha256(raw).hexdigest(),'groups':groups,'banks':banks,'rows':rows}
(root/'.cinder/storage-recovery-20261014/manifest.json').write_text(json.dumps(out,indent=2)+'\n')
print('Verified264targets,12retainedsources,23originalclosurefiles; no images replaced.')
