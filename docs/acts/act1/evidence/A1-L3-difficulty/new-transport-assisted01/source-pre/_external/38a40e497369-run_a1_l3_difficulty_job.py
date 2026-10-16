#!/usr/bin/env python3
"""Prepare/record one explicitly requested L3 job; no import, Git or lock actions.
Running this file launches dev.py engine. --help is read-only.
"""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

# Explicit relevant selection, NOT a global or recursive dependency census.
DEFAULT_SOURCES = '''project.godot
scripts/dev/dev.py
scenes/main.tscn
scenes/acts/act1/a1_l3.tscn
scripts/acts/act1/mushroom_caverns.gd
scripts/acts/act1/mushroom_caverns_route.gd
scripts/acts/act1/mushroom_caverns_full.gd
scripts/acts/act1/mushroom_caverns_route_codec.gd
scripts/acts/act1/mushroom_caverns_layout.gd
scripts/acts/act1/mushroom_selenite.gd
scripts/acts/act1/mushroom_selenite_codec.gd
scripts/acts/act1/mushroom_selenite_approach.gd
scripts/acts/act1/mushroom_selenite_art.gd
scripts/acts/act1/mushroom_grotto_art.gd
scripts/acts/act1/mushroom_cluster_art.gd
scripts/environment/spore_field.gd
scripts/environment/spore_cluster.gd
scripts/environment/spore_repulsion.gd
scripts/environment/scheduler_spore_source_protocol.gd
scripts/combat/repulsion_route.gd
scripts/combat/threat_scheduler.gd
scripts/combat/threat_geometry.gd
scripts/combat/difficulty.gd
scripts/combat/encounter_arrangement.gd
scripts/combat/body_sweep.gd
scripts/combat/lunge_motion.gd
scripts/campaign/shell.gd
scripts/campaign/level.gd
scripts/campaign/attempts.gd
scripts/campaign/save_store.gd
scripts/campaign/snapshot_codec.gd
scripts/campaign/exact_json.gd
scripts/campaign/registry.gd
scripts/settings/game_settings.gd
scripts/ui/campaign_menu.gd
scripts/presentation/camera_framing.gd
scripts/cues/threat_cue.gd
scripts/cues/interaction_cue.gd
scripts/cues/cue_mesh.gd
scripts/player.gd
scripts/game.gd
scripts/equipment.gd
scripts/pixel_sprite.gd
scripts/hud.gd
scripts/attack_footprint.gd
data/design/difficulty_profiles.json
data/design/player_equipment.json
data/campaign/registry.json
tests/acts/act1/a1_l3_difficulty.gd
tests/acts/act1/a1_o2_terminal.gd
tests/acts/act1/a1_o2_campaign.gd'''.splitlines()
SCOPE = 'Explicit selected L3 runtime/test/native dependencies and supplied input reports; existing paired UIDs. Not a global source, asset, resource-graph or filesystem census.'
FOOTER = re.compile(rb'A1-L3 DIFFICULTY: (\d+) checks, (\d+) failures; (?:complete=(true|false); )?report=(\S+)', re.I)
DIAGNOSTIC = re.compile(r'(?:SCRIPT ERROR|Parse Error|ERROR|WARNING):', re.I)

def utc():
    return dt.datetime.now(dt.timezone.utc).isoformat()

def digest(b):
    return hashlib.sha256(b).hexdigest()

def write_json(path, value):
    # Unique run owns this metadata file; atomic replacement never edits a source.
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(value, indent=2) + '\n')
    temp.replace(path)

def resolve_input(root, value):
    return (root / value[6:]).resolve() if value.startswith('res://') else (root / value).resolve()

def snapshot(paths, root, bank=None):
    rows = []
    for path in sorted(paths, key=str):
        key = str(path.relative_to(root)) if path.is_relative_to(root) else '_external/' + digest(str(path).encode())[:12] + '-' + path.name
        row = {'path': str(path), 'bank_path': key, 'exists': path.is_file()}
        if row['exists']:
            try:
                data = path.read_bytes()
            except OSError as exc:
                row.update(exists=False, read_error=repr(exc)); rows.append(row); continue
            row.update(bytes=len(data), sha256=digest(data))
            if bank:
                target = bank / key
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
        rows.append(row)
    return rows

def changed(before, after):
    a = {r['path']: (r['exists'], r.get('sha256')) for r in before}
    b = {r['path']: (r['exists'], r.get('sha256')) for r in after}
    return [p for p in sorted(set(a) | set(b)) if a.get(p) != b.get(p)]

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', required=True, type=Path)
    p.add_argument('--run-dir', required=True, help='New, nonexisting directory underneath checkout .cinder')
    p.add_argument('--arrangement-json', default='data/design/difficulty_profiles.json')
    p.add_argument('--source', action='append', default=[], help='Additional explicit source/input path; repeatable')
    p.add_argument('--source-list', type=Path, help='Additional JSON array of explicit paths; no discovery scan')
    p.add_argument('--gui', action='store_true', help='Omit --headless; never opens/imports separately')
    p.add_argument('fixture_args', nargs=argparse.REMAINDER, help='Use -- followed by exact --case/report arguments')
    args = p.parse_args()
    root = args.root.resolve()
    run = (root / args.run_dir).resolve()
    if not run.is_relative_to((root / '.cinder').resolve()) or run == (root / '.cinder').resolve():
        p.error('--run-dir must be a unique child directory of this checkout .cinder')
    forwarded = args.fixture_args[1:] if args.fixture_args[:1] == ['--'] else args.fixture_args
    if sum(x.startswith('--case=') for x in forwarded) != 1:
        p.error('forward exactly one literal --case=VALUE after --')
    extra = args.source[:]
    if args.source_list:
        supplied = json.loads(args.source_list.read_text())
        if not isinstance(supplied, list) or not all(isinstance(x, str) for x in supplied):
            p.error('--source-list must contain a JSON string array')
        extra.extend(supplied)
    selected = [resolve_input(root, x) for x in DEFAULT_SOURCES + [args.arrangement_json] + extra]
    missing = [str(x) for x in selected if not x.is_file()]
    if missing:
        p.error('required selected inputs missing; nothing launched: ' + ', '.join(missing))
    selected.append(Path(__file__).resolve())
    report_args = []
    for arg in forwarded:
        if '=' in arg and 'report' in arg.split('=', 1)[0]:
            path = resolve_input(root, arg.split('=', 1)[1])
            report_args.append({'argument': arg, 'path': str(path), 'exists_before': path.is_file()})
            if path.is_file(): selected.append(path)
    selected = set(selected)
    # Record both presence and absence of paired UIDs for selected GDScript files.
    selected.update(Path(str(x) + '.uid') for x in list(selected) if x.suffix == '.gd')
    run.mkdir(parents=True, exist_ok=False)
    before = snapshot(selected, root, run / 'source-pre')
    write_json(run / 'source-pre.json', {'scope': SCOPE, 'files': before})
    argv = ['python3', 'scripts/dev/dev.py', 'engine']
    if not args.gui: argv.append('--headless')
    argv += ['--path', '.', '--script', 'tests/acts/act1/a1_l3_difficulty.gd', '--'] + forwarded
    receipt = {'scope': SCOPE, 'checkout': str(root), 'run_directory': str(run), 'command': argv,
               'fixture_arguments': forwarded, 'report_arguments': report_args, 'state': 'prepared',
               'prepared_at': utc(), 'source_pre_manifest_sha256': digest((run/'source-pre.json').read_bytes()),
               'source_count': len(before), 'external_watchdog': 'none; fixture owns its bounded watchdog',
               'native_start_timing_scope': 'Godot banner observation is not an exact process-start or lock-acquisition timestamp',
               'queue_observations': [], 'interrupt_forwarded': False}
    write_json(run / 'receipt.json', receipt)
    start = time.monotonic()
    receipt.update(state='launching', started_at=utc())
    write_json(run / 'receipt.json', receipt)
    child = None
    try:
        with (run/'raw.log').open('wb') as log:
            child = subprocess.Popen(argv, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                     env={**os.environ, 'PYTHONUNBUFFERED': '1'})
            receipt.update(state='running_or_waiting', child_pid=child.pid)
            write_json(run/'receipt.json', receipt)
            def interrupt(signum, _frame):
                # Only our direct dev.py child; no process-group/foreign PID/lock action.
                receipt['interrupt_forwarded'] = True
                if child.poll() is None: child.send_signal(signum)
            prior = signal.signal(signal.SIGINT, interrupt)
            try:
                for line in iter(child.stdout.readline, b''):
                    log.write(line); log.flush()
                    # Raw child bytes are retained even if the caller closes stdout.
                    try:
                        sys.stdout.buffer.write(line); sys.stdout.buffer.flush()
                    except BrokenPipeError:
                        pass
                    text = line.decode('utf-8', errors='replace').strip()
                    elapsed = time.monotonic() - start
                    if 'Waiting for the shared Godot session to close' in text:
                        receipt['queue_observations'].append({'at': utc(), 'elapsed_s': elapsed, 'line': text})
                        receipt['state'] = 'queued_observed'; write_json(run/'receipt.json', receipt)
                    if line.startswith(b'Godot Engine v') and 'native_banner_observed_at' not in receipt:
                        receipt.update(state='native_banner_observed', native_banner_observed_at=utc(),
                                       startup_to_banner_observed_s=elapsed)
                        receipt['selected_input_changes_at_banner'] = changed(before, snapshot(selected, root))
                        if receipt['queue_observations']:
                            receipt['queue_message_to_banner_observed_s'] = elapsed - receipt['queue_observations'][0]['elapsed_s']
                        write_json(run/'receipt.json', receipt)
                receipt['exit_code'] = child.wait()
            finally:
                signal.signal(signal.SIGINT, prior)
    except Exception as exc:
        receipt['runner_error'] = repr(exc)
        # A started child is never silently abandoned or killed/escalated by a timer.
        if child is not None:
            receipt['exit_code'] = child.wait()
    finally:
        receipt.update(state='closed', closed_at=utc(), wall_seconds=time.monotonic()-start)
        after = snapshot(selected, root, run/'source-post')
        write_json(run/'source-post.json', {'scope': SCOPE, 'files': after})
        receipt['selected_input_changes'] = changed(before, after)
        receipt['source_post_manifest_sha256'] = digest((run/'source-post.json').read_bytes())
        raw = (run/'raw.log').read_bytes() if (run/'raw.log').exists() else b''
        receipt['raw_sha256'] = digest(raw)
        receipt['raw_error_warning_lines'] = [x for x in raw.decode('utf-8', errors='replace').splitlines() if DIAGNOSTIC.search(x)]
        footers = FOOTER.findall(raw)
        receipt['footer_count'] = len(footers)
        receipt['footers'] = [{'checks': int(c), 'failures': int(f), 'complete': None if not done else done.lower() == b'true', 'report': q.decode('utf-8', errors='replace')} for c,f,done,q in footers]
        receipt['result'] = 'incomplete_no_unique_footer'
        if len(footers) == 1:
            footer = receipt['footers'][0]
            c, f, report_name = footer['checks'], footer['failures'], footer['report']
            report_path = resolve_input(root, report_name)
            receipt['native_report_original'] = str(report_path)
            try:
                if not report_path.is_relative_to((root/'.cinder').resolve()): raise ValueError('footer report outside checkout .cinder')
                data = report_path.read_bytes(); (run/'native.json').write_bytes(data)
                native = json.loads(data)
                receipt.update(native_report_sha256=digest(data), native_checks=native.get('checks'),
                               native_failures=native.get('failures'), native_elapsed_ms=native.get('elapsed_ms'),
                               first_failure=native.get('first_failure'), native_case=native.get('case'),
                               native_completion_flag=native.get('complete', native.get('scope_complete')))
                agrees = native.get('checks') == c and native.get('failures') == f
                if footer['complete'] is not None:
                    agrees = agrees and receipt['native_completion_flag'] is footer['complete']
                receipt['footer_report_counts_agree'] = agrees
                clean = (receipt.get('exit_code') == 0 and f == 0 and c > 0 and agrees
                         and native.get('first_failure') == {} and not receipt['raw_error_warning_lines']
                         and not receipt['selected_input_changes'] and not receipt.get('selected_input_changes_at_banner')
                         and not receipt.get('runner_error') and not receipt['interrupt_forwarded']
                         and native.get('success') is not False)
                completion = receipt['native_completion_flag']
                receipt['result'] = ('passed' if completion is True else 'zero_failures_completion_unstated') if clean and completion is not False else 'failed_or_incomplete'
            except Exception as exc:
                receipt['report_error'] = repr(exc); receipt['result'] = 'incomplete_report_unreadable'
        write_json(run/'receipt.json', receipt)
    print(json.dumps({'receipt': str(run/'receipt.json'), 'result': receipt['result'], 'exit_code': receipt.get('exit_code')}))
    return 0 if receipt['result'] in ('passed', 'zero_failures_completion_unstated') else 1

if __name__ == '__main__':
    raise SystemExit(main())
