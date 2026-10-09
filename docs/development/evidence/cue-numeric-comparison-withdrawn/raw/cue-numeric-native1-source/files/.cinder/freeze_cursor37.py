from pathlib import Path
import json,hashlib,re,sys,datetime
r=Path.cwd();dest=r/sys.argv[1];seeds=sys.argv[2:];assert seeds and not dest.exists();assert all((r/p).is_file() for p in seeds)
dest.mkdir(parents=True);(dest/'.gdignore').write_bytes(b'');todo=seeds[:];seen=set();missing=set()
while todo:
 rel=todo.pop();p=r/rel
 if rel in seen:continue
 if not p.is_file():missing.add(rel);continue
 seen.add(rel)
 if p.suffix in ['.gd','.tscn','.tres'] or p.name=='project.godot':
  for child in re.findall(r'res://([^\s"\'\)]+)',p.read_text()):
   if (r/child).is_file():todo.append(child)
   else:missing.add(child)
for rel in list(seen):
 if (r/(rel+'.uid')).is_file():seen.add(rel+'.uid')
rows=[]
for rel in sorted(seen):
 b=(r/rel).read_bytes();q=dest/'files'/rel;q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(b);rows.append({'path':rel,'archived_path':str(q.relative_to(dest)),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
d={'schema_version':1,'captured_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'canonical_root':str(r),'scope':'Original targeted prequeue explicit seeds and literal res references including project entry. Bounded source/resource subset only, not complete Godot import/dynamic/globalclass graph; no native/pass claim. .gdignore created first. No later source or UID backfill.','seeds':seeds,'missing_literal_references':sorted(missing),'files':rows};(dest/'manifest.json').write_text(json.dumps(d,indent=2)+'\n');print(json.dumps({'manifest':str(dest.relative_to(r))+'/manifest.json','sources':len(rows),'sha256':hashlib.sha256((dest/'manifest.json').read_bytes()).hexdigest(),'missing_literal_reference_count':len(missing)}))
