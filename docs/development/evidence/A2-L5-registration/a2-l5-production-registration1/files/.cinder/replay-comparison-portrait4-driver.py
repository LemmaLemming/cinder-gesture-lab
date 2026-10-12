"""Bounded graphical validation using canonical dev.py runtime/queue functions.
The lock is acquired before its owned90s native deadline begins. It never kills
other owners or deletes locks. This is a documented dev.py validation wrapper,
not a direct unqueued engine launch; see docs/development/REPLAY_MENU_COMPARISON.md.
"""
from pathlib import Path
import importlib.util,sys
root=Path.cwd(); spec=importlib.util.spec_from_file_location('cinder_dev',root/'scripts/dev/dev.py'); dev=importlib.util.module_from_spec(spec);sys.modules[spec.name]=dev;spec.loader.exec_module(dev)
context=dev.ProjectContext();command=[str(dev.resolve_godot(context)),'--path',str(root),'--script','res://tests/replay_comparison_snapshot_smoke.gd','--','--capture-portraits']
with dev.godot_lock(context.root) as lock_fd:
 print('Canonical dev.py graphical validation wrapper; owned90s bound after queued acquisition.',flush=True)
 result=dev.run_validation(command,context,lock_fd,90,detect_godot_errors=True)
sys.exit(result)
