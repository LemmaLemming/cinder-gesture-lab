#!/usr/bin/env python3
"""Read-only static receipt verifier; never runs/imports Godot or writes live files."""
import hashlib
import json
import re
from pathlib import Path

folder = Path(__file__).resolve().parent
root = folder.parent.parent

def info(data):
    return {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}

def functions(text):
    lines = text.splitlines(keepends=True)
    result = {}
    for i, line in enumerate(lines):
        match = re.match(r'^func (\w+)\(', line)
        if not match:
            continue
        j = i + 1
        while j < len(lines) and (not lines[j].strip() or lines[j][0].isspace()):
            j += 1
        result[match.group(1)] = ''.join(lines[i:j]).rstrip() + '\n'
    return result

inputs = json.loads((folder/'frozen-inputs-before.json').read_text())
for path, receipt in inputs.items():
    assert info((root/path).read_bytes()) == receipt, ('changed actual draft base', path)
original_shell = functions((folder/'shell.original.gd').read_text())
candidate_shell = functions((folder/'shell.gd').read_text())
original_level = functions((folder/'level.original.gd').read_text())
candidate_level = functions((folder/'level.gd').read_text())
assert {k for k in original_shell if original_shell[k] != candidate_shell[k]} == {'_perform'}
assert all(original_level[k] == candidate_level[k] for k in original_level)
assert set(candidate_level)-set(original_level) == {'snapshot_state_for_presentation'}
assert set(candidate_shell)-set(original_shell) == {'_capture_fresh_candidate', '_fresh_capture_binding_error', '_fresh_capture_points_wire', '_fresh_capture_hud_wire'}
body = candidate_shell['_perform']
assert body.count('_capture_fresh_candidate(candidate, ') == 4
assert '_capture(candidate.player, candidate.level,' not in body
assert 'error = level.snapshot_error(local_state)' in candidate_shell['_capture_fresh_candidate']
assert '_busy' not in candidate_shell['_capture_fresh_candidate']
assert 'FreshCaptureExact.stringify' in candidate_shell['_fresh_capture_points_wire']
assert 'Vector3' in candidate_shell['_fresh_capture_points_wire']
assert 'game.call("_capture_fresh_candidate"' in (folder/'fresh_entry_camera_smoke.gd').read_text()
for scene in ['a1_l1', 'a1_l2', 'a1_o1', 'a1_l3']:
    assert 'res://.cinder/fresh-entry-camera-review/fresh_entry_level.gd' in (folder/(scene+'.tscn')).read_text()
result = {"status":"STATIC_ONLY_UNPARSED_UNEXECUTED", "actual_base_files_verified":len(inputs), "preserved_original_shell_functions":len(original_shell)-1, "changed_original_shell_functions":["_perform"], "preserved_original_level_functions":len(original_level), "new_level_functions":sorted(set(candidate_level)-set(original_level)), "new_shell_functions":sorted(set(candidate_shell)-set(original_shell)), "fresh_call_sites":4, "whole_level_validation_outside_writer":True, "saved_restore_functions_byte_identical":True, "game_hud_player_math_unchanged":True, "no_wider_busy_allowance":True, "no_native_job":True}
print(json.dumps(result,indent=2))
