#!/usr/bin/env python3
"""Prepare/record one explicitly requested O1 job; no import, Git mutations or lock actions.
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
DEFAULT_SOURCES = """project.godot
.cinder/local.json
.cinder/a1-l5-retention-checkpoint-adoption.json
docs/development/SHARED_CONTRACT.md
scripts/dev/dev.py
scenes/main.tscn
scenes/player.tscn
scenes/acts/act1/a1_o1.tscn
scenes/acts/act1/a1_l2.tscn
scenes/acts/act1/a1_l2_layout_greybox.tscn
scripts/acts/act1/salvage_circuit.gd
scripts/acts/act1/salvage_circuit_codec.gd
scripts/acts/act1/salvage_circuit_layout.gd
scripts/acts/act1/salvage_circuit_part.gd
scripts/acts/act1/salvage_circuit_scenery.gd
scripts/acts/act1/living_moon_capsule.gd
scripts/acts/act1/lunar_scenery.gd
scripts/acts/act1/crater_gardens.gd
scripts/acts/act1/crater_gardens_layout.gd
scripts/acts/act1/rush_selenite.gd
scripts/acts/act1/rush_selenite_art.gd
scripts/combat/lane_mechanism.gd
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
scripts/character/player_presentations.gd
scripts/hud.gd
scripts/effects.gd
scripts/attack_footprint.gd
data/design/difficulty_profiles.json
data/design/player_equipment.json
data/campaign/registry.json
tests/acts/act1/a1_o1_difficulty.gd
tests/acts/act1/a1_o1_campaign.gd
tests/acts/act1/a1_o1_mechanics.gd
assets/acts/act1/launch/riveted_plate.png
assets/acts/act1/lunar/environment/floor_silver_tile.png
assets/acts/act1/lunar/environment/rock_flat_low_a.png
assets/acts/act1/lunar/environment/rock_flat_low_b.png
assets/acts/act1/lunar/environment/capsule_landed_closed.png
assets/acts/act1/lunar/environment/camp_sleeping_tableau.png
assets/acts/act1/lunar/environment/crescent_performer.png
assets/acts/act1/lunar/environment/grotto_threshold_open.png
assets/acts/act1/lunar/accents/earth_globe.png
assets/acts/act1/lunar/accents/human_star_performer.png
assets/acts/act1/lunar/accents/saturn_performer.png
assets/acts/act1/lunar/rusher_front_standing.png
assets/acts/act1/lunar/rusher_front_crouch.png
assets/acts/act1/lunar/rusher_front_rush.png
assets/acts/act1/lunar/rusher_front_recovery.png
assets/acts/act1/lunar/rusher_side_standing.png
assets/acts/act1/lunar/rusher_side_crouch.png
assets/acts/act1/lunar/rusher_side_rush.png
assets/acts/act1/lunar/rusher_side_recovery.png
assets/acts/act1/lunar/rusher_back_standing.png
assets/acts/act1/lunar/rusher_back_crouch.png
assets/acts/act1/lunar/rusher_back_rush.png
assets/acts/act1/lunar/rusher_back_recovery.png""".splitlines()
# This future local input is recorded absent in the old-writer source bank.
# It is never created/imported by this runner. --arrangement-json requires it.
OPTIONAL_SOURCES = ['data/campaign/act1/a1_o1_difficulty_arrangements.json']
SCOPE = 'Explicit selected O1 host/Codec/layout/part/scenery, accepted campaign/mechanics fixtures, native C30/Lane, protected L2 Story construction, relevant shared controls/transport/framing/presentation and supplied inputs. Paired GDScript UID and future local recipe presence/absence recorded. Not a global or recursive source/asset/resource census.'
FOOTER = re.compile(rb'A1-O1 DIFFICULTY: (\d+) checks, (\d+) failures; complete=(true|false); report=(\S+)', re.I)
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

def git_provenance(root, selected):
    # All three commands are read-only; status covers the named input paths only.
    paths = sorted(str(path.relative_to(root)) for path in selected if path.is_relative_to(root))
    def query(*args):
        result = subprocess.run(['git', *args], cwd=root, capture_output=True, text=True,
                                env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'})
        return {'argv': ['git', *args], 'exit_code': result.returncode,
                'stdout': result.stdout, 'stderr': result.stderr}
    revision = query('rev-parse', 'HEAD')
    branch = query('branch', '--show-current')
    status = query('status', '--short', '--untracked-files=all', '--', *paths)
    return {'scope': 'Read-only Git revision/branch and selected-path status; no Git mutations or repository-wide status claim.',
            'revision': revision['stdout'].strip() if revision['exit_code'] == 0 else None,
            'branch': branch['stdout'].strip() if branch['exit_code'] == 0 else None,
            'selected_path_count': len(paths), 'selected_status': status['stdout'].splitlines(),
            'commands': [revision, branch, status]}

def assertion_evidence(native, raw):
    # Preserve/report actual architecture: structured rows OR explicit native
    # PASS/FAIL stdout rows. Never manufacture an absent assertion list.
    checks, failures = native.get('checks'), native.get('failures')
    if type(checks) is not int or type(failures) is not int or checks < 1 or failures < 0:
        return {'kind': 'invalid_counts', 'agrees': False}
    if 'assertions' in native:
        rows = native['assertions']
        valid = (isinstance(rows, list) and len(rows) == checks
                 and all(isinstance(row, dict) and type(row.get('passed')) is bool
                         and isinstance(row.get('label'), str) and row['label'] for row in rows))
        failed = sum(row['passed'] is False for row in rows) if valid else None
        return {'kind': 'native_assertion_rows', 'row_count': len(rows) if isinstance(rows, list) else None,
                'failed_rows': failed, 'agrees': valid and failed == failures}
    pass_rows = re.findall(rb'^\s*(?:\[PASS\]|PASS:)\s+.+$', raw, re.M)
    fail_rows = re.findall(rb'^\s*(?:\[FAIL\]|FAIL:)\s+.+$', raw, re.M)
    return {'kind': 'actual_stdout_assertion_rows', 'pass_rows': len(pass_rows),
            'fail_rows': len(fail_rows), 'agrees': len(pass_rows) + len(fail_rows) == checks
            and len(fail_rows) == failures}

def source_api_declarations(before, run):
    declarations = []
    for row in before:
        if not row.get('exists') or not row['path'].endswith('.gd'):
            continue
        text = (run / 'source-pre' / row['bank_path']).read_text(errors='replace')
        lines = [{'line': i, 'literal': line.strip()} for i, line in enumerate(text.splitlines(), 1)
                 if re.match(r'^const\s+\w*(?:API_REVISION|SCHEMA_VERSION|WORLD_REVISION|SNAPSHOT_VERSION|LAYOUT_REVISION)\b', line)]
        if lines: declarations.append({'source_path': row['path'], 'source_sha256': row['sha256'], 'declarations': lines})
    return declarations

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', required=True, type=Path)
    p.add_argument('--run-dir', required=True, help='New, nonexisting directory underneath checkout .cinder')
    p.add_argument('--arrangement-json', help='Additional required actual recipe path; omit for old writer before promotion')
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
    selected = [resolve_input(root, x) for x in DEFAULT_SOURCES + ([args.arrangement_json] if args.arrangement_json else []) + extra]
    if args.source_list: selected.append(args.source_list.resolve())
    missing = [str(x) for x in selected if not x.is_file()]
    if missing:
        p.error('required selected inputs missing; nothing launched: ' + ', '.join(missing))
    selected.append(Path(__file__).resolve())
    selected.extend(resolve_input(root, x) for x in OPTIONAL_SOURCES)
    report_args = []
    input_args = []
    outputs = []
    for arg in forwarded:
        if '=' not in arg: continue
        key, value = arg.split('=', 1)
        if key == '--report':
            path = resolve_input(root, value)
            if path in outputs or outputs: p.error('at most one output --report is allowed')
            if not path.is_relative_to((root / '.cinder').resolve()) or path.exists():
                p.error('output report must be a new path inside checkout .cinder')
            outputs.append(path)
            report_args.append({'argument': arg, 'role': 'output_report', 'path': str(path), 'exists_before': False})
        elif key.startswith('--source-') and key.endswith(('-report', '-store')):
            path = resolve_input(root, value)
            if not path.is_file(): p.error('explicit source report/Store missing: ' + str(path))
            item = {'argument': arg, 'role': 'source_input', 'path': str(path), 'exists_before': True}
            input_args.append(item)
            report_args.append(item)
            selected.append(path)
    selected = set(selected)
    # Record both presence and absence of paired UIDs for selected GDScript files.
    selected.update(Path(str(x) + '.uid') for x in list(selected) if x.suffix == '.gd')
    run.mkdir(parents=True, exist_ok=False)
    before = snapshot(selected, root, run / 'source-pre')
    write_json(run / 'source-pre.json', {'scope': SCOPE, 'files': before})
    argv = ['python3', 'scripts/dev/dev.py', 'engine']
    if not args.gui: argv.append('--headless')
    argv += ['--path', '.', '--script', 'tests/acts/act1/a1_o1_difficulty.gd', '--'] + forwarded
    receipt = {'scope': SCOPE, 'checkout': str(root), 'run_directory': str(run), 'command': argv,
               'fixture_arguments': forwarded, 'report_arguments': report_args, 'input_arguments': input_args,
               'requested_case': next(x.split('=', 1)[1] for x in forwarded if x.startswith('--case=')),
               'source_api_declarations': source_api_declarations(before, run),
               'git_before': git_provenance(root, selected),
               'state': 'prepared', 'subprocess_started': False, 'exit_code': None,
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
            receipt.update(state='running_or_waiting', child_pid=child.pid, subprocess_started=True)
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
                        receipt['git_at_native_banner'] = git_provenance(root, selected)
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
        receipt['git_after'] = git_provenance(root, selected)
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
                if report_path in selected: raise ValueError('footer names an existing selected source input, not a new native result')
                if outputs and report_path != outputs[0]: raise ValueError('footer report differs from requested output report')
                data = report_path.read_bytes(); (run/'native.json').write_bytes(data)
                native = json.loads(data)
                if not isinstance(native, dict): raise ValueError('native report must be a JSON object')
                receipt.update(native_report_sha256=digest(data), native_checks=native.get('checks'),
                               native_failures=native.get('failures'), native_elapsed_ms=native.get('elapsed_ms', native.get('wall_ms')),
                               first_failure=native.get('first_failure'), native_case=native.get('case'),
                               native_completion_flag=native.get('complete', native.get('scope_complete')))
                agrees = (native.get('checks') == c and native.get('failures') == f
                          and receipt['native_completion_flag'] is footer['complete'])
                identity = (native.get('case') == receipt['requested_case']
                            and (not native.get('report_path') or resolve_input(root, native['report_path']) == report_path))
                evidence = assertion_evidence(native, raw)
                receipt.update(footer_report_counts_agree=agrees, footer_report_identity_agrees=identity,
                               assertion_evidence=evidence)
                complete = (receipt['native_completion_flag'] is True
                            and all(native[key] is True for key in ('complete','scope_complete') if key in native))
                clean = (receipt.get('subprocess_started') is True and receipt.get('exit_code') == 0
                         and f == 0 and c > 0 and agrees and identity and complete
                         and native.get('success') is True and native.get('first_failure') == {}
                         and evidence['agrees'] and not receipt['raw_error_warning_lines']
                         and not receipt['selected_input_changes'] and not receipt.get('selected_input_changes_at_banner')
                         and not receipt.get('runner_error') and not receipt['interrupt_forwarded'])
                receipt['result'] = 'passed' if clean else 'failed_or_incomplete'
            except Exception as exc:
                receipt['report_error'] = repr(exc); receipt['result'] = 'incomplete_report_unreadable'
        write_json(run/'receipt.json', receipt)
    print(json.dumps({'receipt': str(run/'receipt.json'), 'result': receipt['result'], 'exit_code': receipt.get('exit_code')}))
    return 0 if receipt['result'] == 'passed' else 1

if __name__ == '__main__':
    raise SystemExit(main())
