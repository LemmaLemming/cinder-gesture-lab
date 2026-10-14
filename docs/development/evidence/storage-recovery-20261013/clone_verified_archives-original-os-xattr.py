from pathlib import Path
import os,stat,hashlib,json,subprocess,datetime,uuid
base=Path.cwd();mp=Path('.cinder/immutable-archive-clone-audit/eligible-eight-groups.json');mb=mp.read_bytes();assert hashlib.sha256(mb).hexdigest()=='88ebe84704fea998500f30641d13e6f91027b79900e8b75b42667f00d992c14c';m=json.loads(mb)
assert subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()==m['git_head']
free=lambda:os.statvfs('.').f_bavail*os.statvfs('.').f_frsize
out=Path('.cinder/storage-recovery');log=out/'batch2-actions.jsonl';assert not log.exists()
summary={'manifest':str(mp),'manifest_sha256':hashlib.sha256(mb).hexdigest(),'head':m['git_head'],'started_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'free_before':free(),'method':'Independent APFS COW clones with every target path, bytes, fullmode, mtime, original xattrs and owner preserved; no original evidence content deleted','completed':0}
def verify(p,r,identity=True):
 st=p.lstat();assert stat.S_ISREG(st.st_mode) and not p.is_symlink();assert st.st_dev==r['device'] and st.st_size==r['bytes'] and stat.S_IMODE(st.st_mode)==int(r['mode'],8) and st.st_mtime_ns==r['mtime_ns'],str(p)
 if identity:assert st.st_ino==r['inode'],str(p)
 assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'],str(p)
 return st
sources={}
for g in m['groups']:
 r=g['retained_counterpart'];s=Path(r['path']);st=verify(s,r);assert subprocess.check_output(['git','rev-parse','HEAD:'+str(s)],text=True).strip()==g['git_blob_oid'];sources[str(s)]=(r,st)
try:
 with log.open('x') as f:
  for r in m['rows']:
   p=Path(r['path']);assert str(p).startswith(('docs/development/evidence/','docs/acts/act1/','docs/acts/act2/','assets/acts/act3/evidence/')) and '..' not in p.parts
   st=verify(p,r);s=Path(r['source']);sr,ss=sources[str(s)];assert s.stat().st_ino==ss.st_ino and s.stat().st_mtime_ns==ss.st_mtime_ns
   xa={k:os.getxattr(p,k) for k in os.listxattr(p)};tmp=p.with_name(p.name+'.clone-'+uuid.uuid4().hex)
   subprocess.run(['/bin/cp','-c','-p',str(s),str(tmp)],check=True)
   for k in os.listxattr(tmp):
    if k not in xa:os.removexattr(tmp,k)
   for k,v in xa.items():os.setxattr(tmp,k,v)
   if (tmp.stat().st_uid,tmp.stat().st_gid)!=(st.st_uid,st.st_gid):os.chown(tmp,st.st_uid,st.st_gid)
   os.chmod(tmp,int(r['mode'],8));os.utime(tmp,ns=(r['atime_ns'],r['mtime_ns']))
   ts=verify(tmp,r,False);assert ts.st_ino!=ss.st_ino and ts.st_nlink==1
   cur=p.lstat();assert cur.st_ino==st.st_ino and cur.st_mtime_ns==st.st_mtime_ns and cur.st_size==st.st_size
   os.replace(tmp,p);after=p.stat();assert after.st_ino==ts.st_ino and {k:os.getxattr(p,k) for k in os.listxattr(p)}==xa
   f.write(json.dumps({'path':str(p),'sha256':r['sha256'],'bytes':r['bytes'],'mode':r['mode'],'mtime_ns':r['mtime_ns'],'before_inode':st.st_ino,'after_inode':after.st_ino,'original_owner_and_xattrs_preserved':True})+'\n');f.flush();summary['completed']+=1
   if summary['completed']%200==0:print('Verified and cloned',summary['completed'],'of',len(m['rows']),flush=True)
 summary['status']='COMPLETE'
except Exception as e:
 summary['status']='PARTIAL_STOP';summary['error']=repr(e);raise
finally:
 summary['closed_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();summary['free_after']=free();summary['observed_free_change_bytes']=summary['free_after']-summary['free_before'];(out/'batch2-result.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary),flush=True)
