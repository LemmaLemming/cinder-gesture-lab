from pathlib import Path
import json,hashlib,os,stat,subprocess,uuid,datetime,sys
root=Path.cwd();out=root/'.cinder/storage-recovery-20261014';mp=out/'manifest.json';raw=mp.read_bytes();m=json.loads(raw)
assert sys.argv[1:] in [['pilot'],['remainder']];phase=sys.argv[1];rows=[r for r in m['rows'] if (r['group']=='R1')==(phase=='pilot')]
if phase=='remainder':
 pilot=json.loads((out/'pilot-result.json').read_text());assert pilot['status']=='COMPLETE' and pilot['completed']==22 and pilot['observed_free_change_bytes']>1048576
free=lambda:os.statvfs(root).f_bavail*os.statvfs(root).f_frsize
log=out/(phase+'-actions.jsonl');assert not log.exists()
summary={'phase':phase,'manifest_sha256':hashlib.sha256(raw).hexdigest(),'started_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'free_before':free(),'completed':0,'method':'Independent same-volume APFS clone with original target bytes/mode/mtime/owner/xattrs and every path preserved; retained source unchanged. Volume free-space change is not exclusively attributable.'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(p,r,identity=True):
 s=p.lstat();assert stat.S_ISREG(s.st_mode) and not p.is_symlink() and s.st_nlink==1 and s.st_flags==0
 assert (s.st_size,stat.S_IMODE(s.st_mode),s.st_mtime_ns,s.st_dev,s.st_uid,s.st_gid)==(r['bytes'],r['mode'],r['mtime_ns'],r['device'],r['uid'],r['gid']),str(p)
 if identity:assert s.st_ino==r['inode'],str(p)
 assert sha(p)==r['sha256'],str(p)
 return s
def xa(p):
 names=subprocess.check_output(['/usr/bin/xattr',str(p)],text=True).splitlines()
 return {k:''.join(subprocess.check_output(['/usr/bin/xattr','-p','-x',k,str(p)],text=True).split()).lower() for k in names}
try:
 with log.open('x') as stream:
  for r in rows:
   p=Path(r['path']);source=Path(r['source']);g=m['groups'][r['group']]
   before=verify(p,r);verify(source,g['original']);attrs=xa(p);tmp=p.with_name(p.name+'.clone-'+uuid.uuid4().hex)
   subprocess.run(['/bin/cp','-c','-p',str(source),str(tmp)],check=True)
   copied=xa(tmp)
   for key in copied:
    if key not in attrs:subprocess.run(['/usr/bin/xattr','-d',key,str(tmp)],check=True)
   for key,value in attrs.items():
    if copied.get(key)!=value:subprocess.run(['/usr/bin/xattr','-w','-x',key,value,str(tmp)],check=True)
   if (tmp.stat().st_uid,tmp.stat().st_gid)!=(before.st_uid,before.st_gid):os.chown(tmp,before.st_uid,before.st_gid)
   os.chmod(tmp,r['mode']);os.utime(tmp,ns=(r['atime_ns'],r['mtime_ns']))
   staged=verify(tmp,r,False);assert staged.st_ino!=source.stat().st_ino and xa(tmp)==attrs
   verify(p,r);os.replace(tmp,p);after=verify(p,r,False);assert after.st_ino==staged.st_ino and xa(p)==attrs
   stream.write(json.dumps({'path':str(p),'source':str(source),'sha256':r['sha256'],'bytes':r['bytes'],'mode':r['mode'],'mtime_ns':r['mtime_ns'],'uid':r['uid'],'gid':r['gid'],'xattrs':attrs,'original_inode':before.st_ino,'after_inode':after.st_ino})+'\n');stream.flush();summary['completed']+=1
 summary['status']='COMPLETE'
except Exception as exc:
 summary['status']='PARTIAL_STOP';summary['error']=repr(exc);raise
finally:
 summary.update({'closed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'free_after':free()});summary['observed_free_change_bytes']=summary['free_after']-summary['free_before'];(out/(phase+'-result.json')).write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary))
