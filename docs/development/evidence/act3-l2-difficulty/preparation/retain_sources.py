from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[1];out=HERE/'source-blobs';out.mkdir(exist_ok=True)
sha=lambda b:hashlib.sha256(b).hexdigest();records={};variants={}
def add(path,b,origin):
 h=sha(b);variants.setdefault(path,{})[h]=(b,origin)
# Current named bytes are copied after execution, only when their exact seal hash joins.
for p in json.loads((HERE/'seal-shell-sequential-entries.json').read_text())['files']:
 f=ROOT/p
 if f.is_file():add(p,f.read_bytes(),'copied_after_execution_from_exact_hash_joined_current_file')
p='tests/act3_l2_arrangement_native.gd';s=(ROOT/p).read_text()
start=s.index('\tif paused and is_instance_valid(_game)',s.index('func _tick_safe'))
end=s.index('\tvar reason: String = await super._tick_safe()',start)
s=s[:start]+s[end:]
s=s.replace('\nvar _public_resumes: Array[Dictionary] = []','').replace('"explicit_public_resumes": _public_resumes, ','')
s=s.replace('\n\tvar background_pause_events: Array[int] = []\n\tfunc _notification(what: int) -> void:\n\t\tif what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]: background_pause_events.append(what)\n\t\tsuper._notification(what)','')
add(p,s.encode(),'posthoc_reconstruction_of_prior_driver; exact_original_seal_hash_required')
start=s.index('func _root_approach_candidate() -> Dictionary:');end=s.index('func _prepare_primary_resources()',start);s=s[:start]+s[end:]
add(p,s.encode(),'posthoc_reconstruction_of_prior_driver; exact_original_seal_hash_required')
s=s.replace('_targets.assign(["l2-priority-stalker"] if selected_profile == "challenge" and selected_court == "trunk" else (["l2-trunk-root", "l2-priority-root"] if selected_profile == "challenge" else ["l2-trunk-root"]))','_targets = ["l2-priority-stalker"] if selected_profile == "challenge" and selected_court == "trunk" else (["l2-trunk-root", "l2-priority-root"] if selected_profile == "challenge" else ["l2-trunk-root"])')
add(p,s.encode(),'posthoc_reconstruction_of_prior_driver; exact_original_seal_hash_required')
s=s.replace('selected_starts.size() == 9 and selected_entries.size() == 9 and selected_starts == layout.starts and selected_entries == layout.entries, "real runtime maps equal the independently resolved retained source-slot recipe"','selected_starts.size() == 9 and selected_entries.size() == 9, "real runtime holds complete immutable source start/entry maps"')
add(p,s.encode(),'posthoc_reconstruction_of_prior_driver; exact_original_seal_hash_required')
p='tests/act3_l2_arrangement_shell.gd';s=(ROOT/p).read_text();start=s.index('\t# Each representative TEST relocation');end=s.index('\tvar observed: bool = false',start);s=s[:start]+'\tproduction.player.global_position = Vector3(0, production.player.global_position.y, 10.5)\n\tproduction.menu.resume_requested.emit()\n'+s[end:];add(p,s.encode(),'posthoc_reconstruction_of_prior_driver; exact_original_seal_hash_required')
p=str((HERE/'run.py').relative_to(ROOT));s=(ROOT/p).read_text();block="   if q.portrait:\n    portraits=folder/'portraits';portraits.mkdir();env['CINDER_FOREST_ARRANGEMENT_PORTRAITS']=str(portraits)\n";assert s.count(block)==1;s=s.replace(block,'');s=s.replace("   save(folder/'command.json'",block+"   save(folder/'command.json'");s=s.replace("     if q.portrait:assert d.get('captures') and all(v['unchanged_native_pair'] and v['dimensions']==[540,1170] for v in d['captures'].values()),'Requested portrait captures missing/unstable'\n",'');add(p,s.encode(),'posthoc_reconstruction_of_prior_runner_environment_order; exact_original_seal_hash_required')
# Exact original-seal match required for this reconstructed natural-sun-only leaf.
_h='cc2d9772894388171be8285d45bcd34493ded8ac56a847b92760d6fae30dec27'
_f=out/(_h+'.txt')
if _f.is_file() and sha(_f.read_bytes())==_h:add('tests/act3_l2_arrangement_native.gd',_f.read_bytes(),'posthoc_reconstruction_from_retained_b465_leaf_plus_natural_sun_selector; exact_original_seal_hash_matched; not_stored_at_execution')
old_record=json.loads((HERE/'source-retention.json').read_text()) if (HERE/'source-retention.json').exists() else {}
missing=[];joins={}
for phase in sorted(HERE.iterdir()):
 seal=phase/'seal-used.json'
 if not phase.is_dir() or not seal.is_file():continue
 pins=json.loads(seal.read_text())['files'];entry={}
 for p,h in pins.items():
  if h is None:continue
  if h not in variants.get(p,{}):
   retained=out/(h+'.txt')
   if retained.is_file() and sha(retained.read_bytes())==h:
    prior=old_record.get('phase_joins',{}).get(phase.name,{}).get(p,{})
    add(p,retained.read_bytes(),prior.get('origin','copied_after_execution_from_previously_content_addressed_exact_hash_joined_blob; original capturetime not claimed'))
   else:missing.append({'phase':phase.name,'path':p,'sha256':h});continue
  b,origin=variants[p][h];target=out/(h+'.txt')
  if not target.exists():target.write_bytes(b)
  assert sha(target.read_bytes())==h
  entry[p]={'sha256':h,'blob':'source-blobs/'+target.name,'origin':origin}
 joins[phase.name]=entry
(HERE/'source-retention.json').write_text(json.dumps({'scope':'Named source-byte retention only. Stored at-lock observations remain original; these byte copies/reconstructions are collected after execution and identified distinctly. No claim of original-at-lock blob capture, global/resource/UID or frozen-bank census.','phase_joins':joins,'missing_reconstructions':missing},indent=2)+'\n')
print('Retained',len(list(out.iterdir())),'unique named blobs;',len(joins),'phase maps;',len(missing),'old variants still unmatched')
for row in missing:print(row)
