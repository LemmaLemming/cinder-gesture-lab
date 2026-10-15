from pathlib import Path
import subprocess,json,hashlib,stat
ROOT=Path.cwd();W=Path('/Users/howardchen/.codex/worktrees/campaign-act3/video game idea');REV='155df5602c82787fb18e296f5cbfa5f5597e3f9a';BASE='assets/acts/act3/evidence/A3-O2-native'
def blob(p):return subprocess.check_output(['git','-C',str(W),'show',REV+':'+p])
def sha(b):return hashlib.sha256(b).hexdigest()
index=json.loads(blob(BASE+'/index.json')); assert len(index['artifacts'])==112 and index['file_count_including_index']==113
paths=[BASE+'/'+p for p in index['artifacts']]+[BASE+'/index.json']
paths += ['scripts/acts/act3/quiet_root_circuit.gd','scripts/acts/act3/quiet_root_circuit.gd.uid','scenes/acts/act3/a3_o2_quiet_root_circuit.tscn','data/campaign/act3/a3_o2_encounters.json','tests/acts/act3/quiet_root_circuit_focused.gd','tests/acts/act3/quiet_root_circuit_focused.gd.uid','tests/acts/act3/quiet_root_circuit_optional_shell.gd','tests/acts/act3/quiet_root_circuit_optional_shell.gd.uid','tests/acts/act3/quiet_root_circuit_portrait.gd','tests/acts/act3/quiet_root_circuit_portrait.gd.uid','docs/acts/act3/A3_O2_FOCUSED_HANDOFF.md','data/campaign/act3/levels/A3-O2.md','data/campaign/act3/ACT_MEMORY.md','data/campaign/act3/PROGRESS.md']
assert len(set(paths))==len(paths)
records={}
for p in paths:
 b=blob(p);f=ROOT/p
 if f.exists():
  # Only the two existing canonical owner records are replaced by exact handoff.
  assert p in ['data/campaign/act3/ACT_MEMORY.md','data/campaign/act3/PROGRESS.md','data/campaign/act3/levels/A3-O2.md'] or f.read_bytes()==b,p
 if p.startswith(BASE+'/') and p!=BASE+'/index.json':
  declared=index['artifacts'][p[len(BASE)+1:]];assert len(b)==declared['bytes'] and sha(b)==declared['sha256'],p
 prior=sha(f.read_bytes()) if f.exists() else None
 f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(b);mode=subprocess.check_output(['git','-C',str(W),'ls-tree',REV,'--',p]).decode().split()[0];assert mode in ['100644','100755'];f.chmod(0o755 if mode=='100755' else 0o644)
 records[p]={'sha256':sha(b),'bytes':len(b),'mode':mode,'previous_primary_sha256':prior}
assert sha((ROOT/(BASE+'/index.json')).read_bytes())=='e931c42c01d8e83f54218786068dbe3d9e07af23832541cad3805fc9af1e197d'
Path('.cinder/a3-o2-registration-prepare-20261015/promoted-owner-manifest.json').write_text(json.dumps({'owner_commit':REV,'paths':records,'owner_evidence_files':113,'scope':'Only exact submitted O2 content/evidence/owner records; no shared helper/ledger/config/pinned bank replacement.'},indent=2)+'\n')
print('Promoted exact',len(records),'owner paths,113evidence included; shared helpers untouched.')
