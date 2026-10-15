from pathlib import Path
import json,hashlib,shutil,datetime
ROOT=Path.cwd(); HERE=ROOT/'.cinder/a1-l4-difficulty-20261015'; OUT=ROOT/'docs/development/evidence/act1-l4-difficulty'
assert not OUT.exists(); OUT.mkdir(parents=True);(OUT/'.gdignore').write_text('')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
phases=[]
for f in sorted(HERE.glob('*/result.json')):
 r=json.loads(f.read_text());assert r['closed'] is True
 phases.append({'directory':f.parent.name,'phase':r['phase'],'return_code':r['runner_return_code'],'passed':r['passed'],'native':r.get('native'),'result_sha256':sha(f)})
assert len(phases)==15,len(phases)
assert any(x['phase']=='portrait' and x['native']['checks']==79 for x in phases)
assert any(x['phase']=='assisted' and x['native']['checks']==68 for x in phases)
for f in sorted(HERE.rglob('*')):
 if not f.is_file():continue
 target=OUT/'archive'/f.relative_to(HERE);target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,target);assert sha(f)==sha(target)
for folder in ['.cinder/a1-l4-difficulty-review-20261015']:
 for f in sorted((ROOT/folder).iterdir()):
  if f.is_file():
   target=OUT/'review'/f.name;target.parent.mkdir(exist_ok=True);shutil.copy2(f,target);assert sha(f)==sha(target)
ack=ROOT/'.cinder/agent-chat/cinder-campaign/act1/messages/cc5be1d2-4990-43b4-8450-129e2a6767b2-ACK.json';shutil.copy2(ack,OUT/'ownership-ack.original.json')
seal=json.loads((HERE/'sealed-v7.json').read_text()); source_map={}
for p in seal['files']:
 f=ROOT/p;h=sha(f);target=OUT/'source-objects'/h[:2]/(h+'.blob');target.parent.mkdir(parents=True,exist_ok=True)
 if not target.exists():shutil.copy2(f,target)
 assert sha(target)==h;source_map[p]={'sha256':h,'bytes':f.stat().st_size,'object':str(target.relative_to(OUT)),'tested_seal_sha256':seal['files'][p]}
(OUT/'source-map.json').write_text(json.dumps(source_map,indent=2)+'\n')
(OUT/'visual-inspection.json').write_text(json.dumps({'inspected_by':'Root via actual view_image','image':'archive/portrait-20261015T052646-adaad79a/challenge-committed-circle-guard.png','width':540,'height':1170,'observations':['Hero and both guard silhouettes retain floor contact and separation.','Amber circle outline and center, the west guard warning capsule and its source remain distinguishable.','Nearby open floor around the footprints is visible in the same portrait frame.','HUD/objective/gesture footer remain visible; scenery is sparse and grayscale, with edge ornaments clipped at the viewport boundary.'],'limits':['One representative paused combined state; no moving cue/readability, distant source, later-cycle art, full-route or human balance approval.','Initial TEST HP100 and zero shells; ordinary passive reload remains active and the capture visibly has2/2 shells. Native admission proofs require no blast/invulnerability; this capture is not a zero-ammo playthrough.','Hiding the menu for capture does not alter native scene/cues/geometry.'],'status':'BRIEF_FOCUSED_INSPECTION_COMPLETE'},indent=2)+'\n')
(OUT/'README.md').write_text('''# Court authored approach evidence

This preserves the original targeted queue outputs and independent source reviews for Shared62. The [contract](../../ACT1_L4_DIFFICULTY.md) explains behavior, compatibility and limits. Original absolute paths in copied records describe the actual production run; the matching portable files live under `archive/`. No original evidence bytes were rewritten.

Each phase's source maps observe exactly51 named files/sidecars, not the whole project, dependency graph or UID registry. The initial import adds only the one expected new test UID within that map. Historical phases retain source hashes and original logs; the runner did not archive every historical source body. `source-map.json` and `source-objects/` preserve the final51 current source bodies, with the sole post-test documentation-comment delta called out separately.

Standard68/0, legacy100/0 and preliminary Challenge69/0 are bounded earlier revision results. Final Challenge renderer79/0 and Assisted68/0 use sealed-v7. The final changes after Standard/legacy were confined to new-Challenge eligibility and its extra fixture/renderer observations; their old dispatch and codecs were unchanged. These results are reused within that scope, not relabeled as reruns. Pure7/0 is data-only.

The original observer ScriptError (no complete native report), Standard45/1 and Challenge47/1 remain failures. Multiple parser0 results are separate. The unexecuted seal-v3 flank/HP23 fixture proposal was superseded before a job; it has no execution credit. The exact original373 producer packets are reused as literal legacy inputs, not newly executed historical producers.

Canonical dev owns/waits its direct child through the shared queue. A zero proves the direct child returned0; nonzero dev values can be synthetic detected-error/timeout outcomes. All15 phases are closed. No foreign process/lock or worker checkout was changed. This does not establish full routes, all-kit balance, performance/FPS, later-act policy completion, mobile or release readiness.
''')
files={str(f.relative_to(OUT)):{'sha256':sha(f),'bytes':f.stat().st_size} for f in sorted(OUT.rglob('*')) if f.is_file()}
index={'created':datetime.datetime.now(datetime.timezone.utc).isoformat(),'component':'act1-court-aggregate-3','publication_api':'campaign-shared-62','accepted_levels_unchanged':21,'phases':phases,'observed_named_sources':51,'files':files,'scope':'Exact original artifact copies, final selected source objects, independent read-only reviews and one inspected actual portrait. Not global/frozenbank census, fullroute, performance or newlevel acceptance.'};(OUT/'index.json').write_text(json.dumps(index,indent=2)+'\n');print('evidence',len(files)+1,'files',sum(f.stat().st_size for f in OUT.rglob('*') if f.is_file()),'index',sha(OUT/'index.json'))
