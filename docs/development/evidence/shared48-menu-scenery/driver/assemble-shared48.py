from pathlib import Path
import json,hashlib,datetime,os
root=Path.cwd();target=root/'docs/development/evidence/shared48-menu-scenery';target.mkdir(parents=True,exist_ok=True)
boundary=target/'.gdignore'
if not boundary.exists():boundary.write_text('\n')
items=[];jobs=[]
def put(source,relative,role):
 source=Path(source);destination=target/relative;assert source.is_file(),source;destination.parent.mkdir(parents=True,exist_ok=True);data=source.read_bytes()
 if destination.exists():assert destination.read_bytes()==data,('existing archive differs',destination)
 else:destination.write_bytes(data);os.chmod(destination,source.stat().st_mode&0o777)
 h=hashlib.sha256(data).hexdigest();assert hashlib.sha256(destination.read_bytes()).hexdigest()==h
 items.append({'path':str(destination.relative_to(target)),'origin':str(source.relative_to(root)),'bytes':len(data),'sha256':h,'role':role})
tags=['menu-scenery-import1','menu-scenery-native1','menu-scenery-native2','menu-scenery-native3','menu-scenery-portrait4','menu-scenery-portrait5','menu-scenery-portrait6','menu-scenery-comparison7']
for tag in tags:
 source=root/'.cinder'/(tag+'-source');manifest=json.loads((source/'manifest.json').read_text());result=json.loads((root/'.cinder'/(tag+'-result.json')).read_text())
 assert result['source_manifest_sha256']==hashlib.sha256((source/'manifest.json').read_bytes()).hexdigest()
 assert result['wrapper_log_sha256']==hashlib.sha256((root/result['wrapper_log']).read_bytes()).hexdigest()
 assert len(manifest['files'])==result['source_count']
 for original,relative,role in [(source/'manifest.json','manifest.json','original frozen manifest'),(root/'.cinder'/(tag+'-result.json'),'result.json','original observed closure'),(root/result['wrapper_log'],'wrapper.log','original full native log')]:put(original,tag+'/'+relative,role)
 for row in manifest['files']:
  original=source/row['archived_path'];assert original.stat().st_size==row['bytes'] and hashlib.sha256(original.read_bytes()).hexdigest()==row['sha256'];put(original,tag+'/'+row['archived_path'],'original frozen source')
 jobs.append({'tag':tag,'sources':len(manifest['files']),'result':tag+'/result.json','manifest':tag+'/manifest.json','log':tag+'/wrapper.log','original_returncode':result['returncode'],'scope':result['scope']})
 for line in (root/result['wrapper_log']).read_text().splitlines():
  if line.startswith(('REPLAY_COMPARISON_PORTRAIT ','MENU_SCENERY_TEST_PORTRAIT ')):
   pairs=dict(json.loads(line.split(' ',1)[1])['value'][1]);image_path=Path(pairs['path'][1]);assert hashlib.sha256(image_path.read_bytes()).hexdigest()==pairs['sha256'][1];put(image_path,tag+'/portraits/'+image_path.name,'original actual native PNG')
extras=[('.cinder/menu-scenery-native2-scope-qualification.json','qualifications/native2-nonclean.json'),('.cinder/menu-scenery-portrait5-decoded-receipts.json','derived/original5-float64-strings.json'),('.cinder/menu-scenery-portrait5-decoded-receipts2.json','derived/corrected5-decoded-receipts.json'),('.cinder/menu-scenery-final-decoded-receipts.json','derived/final6-decoded-receipts.json'),('.cinder/shared-menu-scenery-draft/final-graphical6-review.json','reviews/reference-final6.json'),('.cinder/menu-scenery-independent-final6-audit.json','reviews/systems-final6.json'),('.cinder/shared-menu-scenery-draft/menu_scenery.gd','drafts/original-scenery.gd'),('.cinder/shared-menu-scenery-draft/source-manifest.json','drafts/scenery-source-manifest.json'),('.cinder/shared-menu-scenery-draft/manifest.json','drafts/scenery-release-manifest.json'),('.cinder/shared-menu-scenery-draft/README.md','drafts/scenery-README.md'),('.cinder/shared-menu-scenery-test-draft/test-leaf.gd','drafts/original-test.gd'),('.cinder/shared-menu-scenery-test-draft/manifest.json','drafts/test-manifest.json'),('.cinder/shared-menu-scenery-test-draft/README.md','drafts/test-README.md'),('.cinder/menu-scenery-tools.py','driver/menu-scenery-tools.py'),('.cinder/assemble-shared48.py','driver/assemble-shared48.py'),('.cinder/a3-shared47-independent-verification.json','coordination/actual-a3-shared47.json')]
for origin,relative in extras:put(root/origin,relative,'qualified derivative/review/driver or original as-read private draft')
for row in json.loads((root/'.cinder/menu-scenery-import1-result.json').read_text())['added_uid_rows']:put(root/row['path'],'late-metadata/'+row['path'],'genuine post-import UID output; no earlier backfill')
assert len({x['path'] for x in items})==len(items)
index={'schema_version':1,'created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'api_revision':'campaign-shared-48','jobs':jobs,'original_source_count':sum(j['sources'] for j in jobs),'artifact_count':len(items),'artifacts':items,'scope':'Original bounded prequeue source copies/manifests/full logs/closures preserved at exact attribution. Native1 error/nofooter, native2 functional360/0 with120ERRORs nonclean, native3 clean360/0, portrait4 clean722/0pre-mask, portrait5 failed725/3, final6 clean725/0+eightinspectedPNG, affectedcomparison7 clean331/0. Static paused menu/UI + TEST themes only; no new act acceptance/currentA2-A3gameplay/GUI hit-test/earnedroute/fullroute/device/performance claim. Two new UID outputs are separate from694 original import inputs. Initial5-derived metrics kept float64 strings; corrected5/final6 derivatives explicitly decode original little-endian float64 bits; original logs/images unchanged.'}
(target/'index.json').write_text(json.dumps(index,indent=2)+'\n')
print(json.dumps({'index':str((target/'index.json').relative_to(root)),'sha256':hashlib.sha256((target/'index.json').read_bytes()).hexdigest(),'artifacts':len(items),'original_sources':index['original_source_count'],'jobs':len(jobs)},indent=2))
