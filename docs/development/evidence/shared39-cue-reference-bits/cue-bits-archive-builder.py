from pathlib import Path
import json,hashlib,shutil,datetime
root=Path.cwd();dest=root/'docs/development/evidence/shared39-cue-reference-bits'
assert not dest.exists()
dest.mkdir(parents=True);(dest/'.gdignore').write_bytes(b'');(dest/'.gitattributes').write_text('* -text\n')
tags=['cue-bits-native1','cue-bits-performance1','cue-bits-baseline1','cue-bits-performance2'];receipts=[]
for tag in tags:
 source=root/'.cinder'/f'{tag}-source';manifest=source/'manifest.json';m=json.loads(manifest.read_text())
 expected={'manifest.json','.gdignore',*[row['archived_path'] for row in m['files']]}
 actual={str(p.relative_to(source)) for p in source.rglob('*') if p.is_file()};assert actual==expected,(tag,'membership')
 for row in m['files']:
  b=(source/row['archived_path']).read_bytes();assert len(b)==row['bytes'] and hashlib.sha256(b).hexdigest()==row['sha256'],(tag,row['path'])
 closure=json.loads((root/'.cinder'/f'{tag}-closure.json').read_text());assert closure['observed_parent_exit_code']==0 and closure['failures']==0 and closure['source_count']==len(m['files']) and closure['source_manifest_sha256']==hashlib.sha256(manifest.read_bytes()).hexdigest(),tag
 out=dest/'runs'/tag;out.mkdir(parents=True);shutil.copytree(source,out/'source')
 for suffix in ['-submission.json','-closure.json','.native.log','.wrapper.log']:
  p=root/'.cinder'/f'{tag}{suffix}';shutil.copyfile(p,out/p.name)
 for key,log in closure['logs'].items():
  b=(root/log['path']).read_bytes();assert len(b)==log['bytes'] and hashlib.sha256(b).hexdigest()==log['sha256'] and not log['diagnostics'],(tag,key)
 if tag!='cue-bits-native1':
  p=root/'.cinder'/f'{tag}-report.json';shutil.copyfile(p,out/p.name)
 receipts.append({'run':tag,'source_manifest':str((out/'source/manifest.json').relative_to(dest)),'original_source_count':len(m['files']),'closure':str((out/f'{tag}-closure.json').relative_to(dest)),'checks':closure['checks'],'failures':0,'observed_exit_code':0})
for name in ['cue-bits-selection.json','cue-bits-publication-review.json','cue-bits-authored-sequence1-qualification.json','cue-bits-archive-builder.py']:
 p=root/'.cinder'/name;shutil.copyfile(p,dest/name)
rows=[]
for p in sorted(dest.rglob('*')):
 if p.is_file():
  b=p.read_bytes();rows.append({'path':str(p.relative_to(dest)),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
j={'schema_version':1,'packaged_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'canonical_root':str(root),'publication':'campaign-shared-39 candidate, exact commit recorded in durable progress/mailbox after scoped publication','scope':'Four observed closed native runs,508 original bounded explicit/literal input files with separate full native/wrapper logs and immutable source manifests. Original paths/timestamps/API attribution retained; portable mappings are provided here. Literal source closures are not complete import/globalclass graphs. Test-only one-Box timing is not full authored campaign/16visual/portrait/FPS/mobile or tail-latency acceptance. Prepared unrelated data-reader fixture was withdrawn before execution and receives no native credit.','runs':receipts,'artifacts':rows,'artifact_count':len(rows),'artifact_bytes':sum(row['bytes'] for row in rows),'index_excluded_from_artifact_hashes':True}
(dest/'index.json').write_text(json.dumps(j,indent=2)+'\n');print(json.dumps({'index':str((dest/'index.json').relative_to(root)),'sha256':hashlib.sha256((dest/'index.json').read_bytes()).hexdigest(),'artifact_count':len(rows),'artifact_bytes':j['artifact_bytes']}))
