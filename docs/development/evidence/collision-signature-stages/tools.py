"""SOURCE ONLY: Root may use the canonical queue after reviewing/selecting copies.

Never selects or restores runtime copies, runs imports, removes locks or starts
an unqueued native process. Freezer scope is explicit/literal bounded resources
plus all active UID bytes; it is not a complete dynamic/import resource graph.
"""
from pathlib import Path
import datetime
import hashlib
import importlib.util
import json
import math
import os
import re
import shutil
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
PROFILE = 'res://.cinder/collision-signature-profile/profile.gd'
SELFTEST = 'res://.cinder/collision-signature-profile/sink_selftest.gd'
MODES = {'parse', 'sinkparse', 'sinktest', 'profile'}
ENGINE_PIN = {'path': '.tools/Godot.app/Contents/MacOS/Godot', 'bytes': 351312912,
              'sha256': 'c7cccbf8fb143e34e02fd6521e09be2c2b974f0d5db080b19071c9c570718ccf', 'mode': 0o755}
PRIOR_PIN = {
    '.cinder/native-boundary-profile/jobs/native-boundary-profile1/result.json': '07dddf8431eddba36088e956214776f2c66213021b46c473774dedab8d14fca9',
    '.cinder/native-boundary-profile/jobs/native-boundary-profile1/raw.log': '02d584c47a9a922e2cc1134130b758d895470515195827867e4f662d58601ef7',
}


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def uids():
    rows = []
    for directory, dirs, files in os.walk(ROOT):
        p = Path(directory)
        if p != ROOT and (p / '.gdignore').exists():
            dirs[:] = []
            continue
        dirs[:] = [n for n in dirs if n not in {'.git', '.godot', '.tools', '.cinder', 'exports', 'captures', '__pycache__'}]
        for name in files:
            if name.endswith('.uid'):
                q = p / name
                rows.append({'path': str(q.relative_to(ROOT)), 'sha256': sha(q), 'uid': q.read_text().strip(), 'bytes': q.stat().st_size, 'mode': q.stat().st_mode & 0o777})
    return sorted(rows, key=lambda row: row['path'])


def dev_module():
    spec = importlib.util.spec_from_file_location('collision_signature_cinder_dev', ROOT / 'scripts/dev/dev.py')
    dev = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = dev
    spec.loader.exec_module(dev)
    return dev


def engine_pin():
    dev = dev_module()
    context = dev.ProjectContext()
    actual = dev.resolve_godot(context).resolve()
    assert actual == (ROOT / ENGINE_PIN['path']).resolve(), actual
    assert actual.stat().st_size == ENGINE_PIN['bytes'] and sha(actual) == ENGINE_PIN['sha256'] and actual.stat().st_mode & 0o777 == ENGINE_PIN['mode']
    return {**ENGINE_PIN, 'absolute_path': str(actual)}


def selected_sources(mode):
    proof = json.loads((HERE / 'statement-proof.json').read_text())
    for row in proof['sources']:
        wanted = row['candidate_sha256'] if mode in {'parse', 'profile'} else row['original_sha256']
        assert sha(ROOT / row['path']) == wanted, (mode, row['path'])
        assert (ROOT / row['path']).stat().st_mode & 0o777 == row['original_mode']
    return proof


def freeze(tag, mode):
    assert mode in MODES and re.fullmatch(r'[a-z0-9-]+', tag)
    target = HERE / 'jobs' / tag
    assert not target.exists(), target
    # A small source-only proposal can be prepared under storage pressure;
    # actual freezer banks wait until Root has recovered enough free space.
    assert shutil.disk_usage(HERE).free >= 256 * 1024 * 1024, 'Need 256MiB free before a new bounded source archive'
    selected_sources(mode)
    pin = engine_pin()
    for path, digest in PRIOR_PIN.items():
        assert sha(ROOT / path) == digest, path
    seeds = [PROFILE[6:] if mode in {'parse', 'profile'} else SELFTEST[6:],
             str((HERE / 'tools.py').relative_to(ROOT)), str((HERE / 'sink.gd').relative_to(ROOT)),
             'scripts/dev/dev.py', 'project.godot', '.cinder/local.json',
             '.godot/global_script_class_cache.cfg', 'data/campaign/registry.json',
             'data/design/difficulty_profiles.json', 'data/design/player_equipment.json',
             'scripts/environment/scheduler_spore_source_protocol.gd', 'scripts/combat/repulsion_route.gd',
             '.cinder/a1-l3-stage-diagnostic4.gd', '.cinder/a1-l3-stage-source/campaign.json',
             'scenes/acts/act1/a1_l3.tscn', 'scripts/acts/act1/mushroom_caverns_full.gd',
             '.cinder/native-boundary-profile/build.py', '.cinder/native-boundary-profile/profile.gd',
             '.cinder/native-boundary-profile/sink.gd', *PRIOR_PIN]
    seeds += [str((HERE / name).relative_to(ROOT)) for name in
              ['build.py', 'profile.gd', 'sink_selftest.gd', 'protocol.original.gd', 'route.original.gd',
               'protocol.candidate.gd', 'route.candidate.gd', 'profile-base-original.gd',
               'sink-base-original.gd', 'statement-proof.json', 'instrumentation.patch',
               'fixture.patch', 'sink.patch', 'static-validation.json', 'plan.json', 'manifest.json']]
    seen, todo = set(), seeds[:]
    while todo:
        relative = todo.pop()
        source = ROOT / relative
        assert source.is_file(), source
        if relative in seen:
            continue
        seen.add(relative)
        if source.suffix in {'.gd', '.tscn', '.tres', '.json'}:
            for child in re.findall(r'res://([^\s"\'\)]+)', source.read_text()):
                if (ROOT / child).is_file():
                    todo.append(child)
    uid_rows = uids()
    seen.update(row['path'] for row in uid_rows)
    target.mkdir(parents=True)
    (target / '.gdignore').write_bytes(b'')
    rows = []
    for relative in sorted(seen):
        source = ROOT / relative
        payload = source.read_bytes()
        q = target / 'source' / relative
        q.parent.mkdir(parents=True, exist_ok=True)
        q.write_bytes(payload)
        os.chmod(q, source.stat().st_mode & 0o777)
        rows.append({'path': relative, 'archived_path': str(q.relative_to(target)), 'bytes': len(payload), 'sha256': sha(q), 'mode': source.stat().st_mode & 0o777})
    value = {'at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'mode': mode, 'files': rows,
             'uids': uid_rows, 'seeds': seeds, 'engine_binary': pin,
             'scope': 'Explicit/literal bounded resource subset plus every active UID byte/mode and actual executable SHA; not a complete dynamic/import graph. Original genuine CP2/GUI Continue/Resume/one TEST Hero placement/native callbacks; primitive temporary observation only, no optimization/FPS/current-view/save/acceptance claim.'}
    (target / 'manifest.json').write_text(json.dumps(value, indent=2) + '\n')
    print(json.dumps({'tag': tag, 'mode': mode, 'files': len(rows), 'uids': len(uid_rows), 'engine_sha256': pin['sha256'], 'manifest_sha256': sha(target / 'manifest.json')}))


def verify(target, manifest):
    for row in manifest['files']:
        for path in [ROOT / row['path'], target / row['archived_path']]:
            assert path.stat().st_size == row['bytes'] and sha(path) == row['sha256'] and path.stat().st_mode & 0o777 == row['mode'], path
    assert uids() == manifest['uids']
    assert engine_pin() == manifest['engine_binary']


def decode_exact(path):
    raw = path.read_bytes()
    assert len(raw) <= 8 * 1024 * 1024
    envelope = json.loads(raw)
    assert set(envelope) == {'api_revision', 'schema_version', 'value'} and envelope['api_revision'] == 'exact-json-1' and envelope['schema_version'] == 1
    budget = [262144]

    def decode(node, depth=0):
        budget[0] -= 1
        assert budget[0] >= 0 and depth <= 64 and isinstance(node, list) and node and isinstance(node[0], str)
        kind = node[0]
        if kind == 'null':
            assert len(node) == 1
            return None
        assert len(node) == 2
        value = node[1]
        if kind == 'boolean':
            assert type(value) is bool
            return value
        if kind == 'string':
            assert type(value) is str
            return value
        if kind == 'integer':
            assert type(value) is str and re.fullmatch(r'-?(?:0|[1-9][0-9]*)', value)
            parsed = int(value)
            assert str(parsed) == value and abs(parsed) <= 9007199254740991
            return parsed
        if kind == 'float64':
            assert type(value) is str and re.fullmatch(r'[0-9a-f]{16}', value)
            parsed = struct.unpack('<d', bytes.fromhex(value))[0]
            assert math.isfinite(parsed)
            return parsed
        assert isinstance(value, list) and len(value) <= 16384
        if kind == 'array':
            return [decode(child, depth + 1) for child in value]
        assert kind == 'dictionary'
        result, keys = {}, []
        for entry in value:
            assert isinstance(entry, list) and len(entry) == 2 and type(entry[0]) is str and entry[0] not in result
            keys.append(entry[0])
            result[entry[0]] = decode(entry[1], depth + 1)
        assert keys == sorted(keys), 'Stringifier canonical dictionary order'
        return result

    return decode(envelope['value'])


def witness_files(target, streams):
    traced = []
    for line in streams['native'].splitlines():
        marker = line.find('{')
        if marker >= 0:
            try:
                row = json.loads(line[marker:])
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict) and row.get('stage') == 'collision_signature_profile_paused_witness':
                traced.append(row)
    assert len(traced) == 1, 'One actual native retained witness trace required'
    trace = traced[0]
    rows, decoded = {}, {}
    for key, filename, prefix in [('native', 'focused-native.exact.json', 'native'), ('packets', 'complete19-packets.exact.json', 'packet')]:
        path = target / 'observed' / filename
        expected = trace[prefix + '_file']
        assert expected['path'] == 'res://' + str(path.relative_to(ROOT)) and expected['exact_decoded_and_reencoded'] is True
        assert path.stat().st_size == trace[prefix + '_bytes'] == expected['bytes']
        assert sha(path) == trace[prefix + '_sha256'] == expected['sha256']
        decoded[key] = decode_exact(path)
        rows[key] = {'path': str(path.relative_to(ROOT)), 'bytes': path.stat().st_size, 'sha256': sha(path), 'mode': path.stat().st_mode & 0o777, 'host_exact_envelope_decoded': True, 'native_trace_bytes_hash_match': True}
    unit = decoded['packets']
    assert isinstance(unit, dict) and set(unit) == {'scheduler', 'player', 'actors'} and len(unit['actors']) == 19
    native = decoded['native']
    assert isinstance(native, dict) and set(native) == {'references', 'diagnostics', 'focused_native', 'scope'} and len(native['references']) == 8 and len(native['focused_native']['sources']) == 19 and native['focused_native']['paused'] is True
    rows['decoded_scope'] = {'packet_actor_count': 19, 'native_reference_count': 8, 'focused_native_actor_count': 19, 'paused': True,
                             'qualification': 'Host decodes the retained Exact envelope and verifies literal bytes/hash joins; no new native replay, full arbitrary Script-state capture, parent optical save or phase acceptance.'}
    return rows


def run(tag, mode):
    target = HERE / 'jobs' / tag
    mp = target / 'manifest.json'
    manifest = json.loads(mp.read_text())
    assert manifest['mode'] == mode
    verify(target, manifest)
    log, result = target / 'wrapper.log', target / 'result.json'
    assert not log.exists() and not result.exists()
    command = [sys.executable, '-B', str(Path(__file__).relative_to(ROOT)), 'engine', tag, mode]
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    with log.open('xb') as output:
        child = subprocess.Popen(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT)
        code = child.wait()
    closure_error = ''
    try:
        verify(target, manifest)
    except Exception as error:
        closure_error = str(error) or type(error).__name__
    raw_path = target / 'raw.log'
    streams = {'wrapper': log.read_text(errors='replace'), 'native': raw_path.read_text(errors='replace') if raw_path.exists() else ''}
    problems = {}
    for name, text in streams.items():
        problems[name] = {'script_parse_compile': len(re.findall(r'SCRIPT ERROR|Parse Error|Compile Error', text)),
                          'errors': len(re.findall(r'(?m)^ERROR:', text)), 'warnings': len(re.findall(r'(?m)^WARNING:', text)),
                          'failures': len(re.findall(r'FAIL:', text)), 'leak_or_unclaimed': len(re.findall(r'leaked|Orphan StringName|unclaimed', text, re.I))}
    pattern = r'Collision signature profile: (\d+) checks, (\d+) failures;' if mode == 'profile' else r'Collision signature sink self-test: (\d+) checks, (\d+) failures'
    footers = re.findall(pattern, streams['wrapper'])
    clean = not any(sum(row.values()) for row in problems.values())
    successful = code == 0 and clean and not closure_error and (mode.endswith('parse') or bool(footers) and int(footers[-1][1]) == 0)
    witnesses, witness_error = {}, ''
    if mode == 'profile':
        try:
            witnesses = witness_files(target, streams)
        except Exception as error:
            witness_error = str(error) or type(error).__name__
            successful = False
    value = {'started_at': started, 'closed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
             'command': command, 'child_pid': child.pid, 'returncode': code, 'clean': clean, 'successful_scope': successful,
             'mode': mode, 'source_count': len(manifest['files']), 'manifest_sha256': sha(mp),
             'source_archive_current_exact_at_closure': not closure_error, 'active_uids_unchanged': not closure_error,
             'engine_binary': manifest['engine_binary'], 'engine_binary_verified_at_closure': not closure_error,
             'closure_error': closure_error, 'diagnostics': problems, 'footers': footers,
             'streams': {name: {'path': str(path.relative_to(ROOT)), 'bytes': path.stat().st_size, 'sha256': sha(path)} for name, path in [('wrapper', log), ('native', raw_path)] if path.exists()},
             'actual_retained_witnesses': witnesses, 'witness_verification_error': witness_error, 'scope': manifest['scope']}
    result.write_text(json.dumps(value, indent=2) + '\n')
    print(json.dumps({'tag': tag, 'mode': mode, 'returncode': code, 'clean': clean, 'successful_scope': successful, 'footers': footers, 'result_sha256': sha(result), 'closure_error': closure_error, 'witness_verification_error': witness_error}))
    sys.exit(0 if successful else 1)


def engine(tag, mode):
    target = HERE / 'jobs' / tag
    manifest = json.loads((target / 'manifest.json').read_text())
    dev = dev_module()
    context = dev.ProjectContext()
    script = PROFILE if mode in {'parse', 'profile'} else SELFTEST
    command = [str(dev.resolve_godot(context)), '--path', str(ROOT), '--headless', '--script', script, '--log-file', str(target / 'raw.log')]
    if mode.endswith('parse'):
        command += ['--check-only']
    elif mode == 'profile':
        # Actual clean closures must exist; names are separate fixed custody,
        # so a sink-only parse cannot substitute for the actual profile parse.
        for prior_tag, prior_mode in [('collision-signature-parse2', 'parse'), ('collision-signature-sinktest2', 'sinktest')]:
            prior = json.loads((HERE / 'jobs' / prior_tag / 'result.json').read_text())
            assert prior['mode'] == prior_mode and prior['successful_scope'] is True
        command += ['--', '--measurement-label=' + tag]
    elif mode == 'sinktest':
        prior = json.loads((HERE / 'jobs' / 'collision-signature-sinkparse1' / 'result.json').read_text())
        assert prior['mode'] == 'sinkparse' and prior['successful_scope'] is True
    (target / 'submission.json').write_text(json.dumps({'engine_command': command, 'mode': mode, 'engine_binary': manifest['engine_binary'], 'deadline_s_after_queue_acquisition': 90}, indent=2) + '\n')
    with dev.godot_lock(context.root) as lock:
        verify(target, manifest)
        print('Canonical dev.py queue acquired; owned 90s deadline starts now.', flush=True)
        code = dev.run_validation(command, context, lock, 90, detect_godot_errors=True)
    sys.exit(code)


if __name__ == '__main__':
    action, tag, mode = sys.argv[1:4]
    assert action in {'freeze', 'run', 'engine'} and mode in MODES and re.fullmatch(r'[a-z0-9-]+', tag)
    if action == 'freeze':
        freeze(tag, mode)
    elif action == 'run':
        run(tag, mode)
    else:
        engine(tag, mode)
