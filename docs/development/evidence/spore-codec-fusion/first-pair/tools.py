"""Source-only paired native measurement runner. Never selects runtime or imports.
One shared input bank; only the exact original/fused Route and Protocol may differ.
All native children use canonical dev.py godot_lock/run_validation with 90s bound.
"""
from pathlib import Path
import ast, datetime, hashlib, importlib.util, json, math, os, re, shutil, struct, subprocess, sys

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
SCRIPT = 'res://.cinder/spore-fusion-measure-prep/measure.gd'
ROUTE = 'scripts/combat/repulsion_route.gd'
PROTOCOL = 'scripts/environment/scheduler_spore_source_protocol.gd'
ROUTE_SHA = {'baseline': '2bdfd3ea6997beceb0d5d26eb27e8520214872b0e81e1d7f8039afbf6d53b30a',
             'candidate': '871ee704b4ce43c262362d95689ae434fcb37c276e7b36ab0bf9196ec2c7119c'}
PROTOCOL_SHA = {'baseline': 'a01b5481e3d06f64f65973fff075c4cbe622e4a1129c1646ee228c103b8523b5', 'candidate': '2a624f1c3d63b262b622a9f2767a1f481ad76f2637292eb826512fe83edb1607'}
HELPER = 'scripts/campaign/codec_exact_reference.gd'
HELPER_SHA = '5c2e387254cc68edc636a5ff614cec707e110da50ba4a4588ce45274f70c29aa'
CANDIDATE = '.cinder/spore-fusion-measure-prep/variants/candidate/route.gd.txt'
CANDIDATE_PROTOCOL = '.cinder/spore-fusion-measure-prep/variants/candidate/protocol.gd.txt'
ENGINE_SHA = 'c7cccbf8fb143e34e02fd6521e09be2c2b974f0d5db080b19071c9c570718ccf'
ACTORS = {'breathing-1', 'breathing-2', 'breathing-3', 'court-1', 'court-2', 'court-3', 'court-guard', 'lone-guard', 'umbrella-1', 'umbrella-2', 'umbrella-3', *[f'crossed-{i}' for i in range(1, 9)]}
FOCUSED_KEYS = {'paused', 'shell_id', 'shell_script', 'level_id', 'level_script', 'hero_id', 'hero_script', 'controller_id', 'controller_script', 'controller_clock_bits', 'player_clock_bits', 'input', 'aim', 'camera_pose', 'camera_size', 'camera_projection', 'camera_focus', 'hud_safe', 'attempts', 'menu', 'beat_index', 'room_stage', 'completed_beats', 'sources'}
SOURCE_KEYS = {'node_id', 'script_id', 'pose', 'velocity', 'grounded', 'collision_id', 'shape_id', 'collision_pose', 'disabled', 'hp', 'max_hp', 'dead', 'dormant', 'body'}


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda: f.read(1024 * 1024), b''): h.update(b)
    return h.hexdigest()


def row(path):
    return {'path': str(path.relative_to(ROOT)), 'bytes': path.stat().st_size,
            'sha256': sha(path), 'mode': path.stat().st_mode & 0o777}


def uids():
    result = []
    for directory, dirs, files in os.walk(ROOT):
        p = Path(directory)
        if p != ROOT and (p / '.gdignore').exists(): dirs[:] = []; continue
        dirs[:] = [n for n in dirs if n not in {'.git', '.godot', '.tools', '.cinder', 'exports', 'captures', '__pycache__'}]
        result.extend(row(p / n) for n in files if n.endswith('.uid'))
    return sorted(result, key=lambda r: r['path'])


def dev_module():
    spec = importlib.util.spec_from_file_location('spore_fusion_measure_cinder_dev', ROOT / 'scripts/dev/dev.py')
    dev = importlib.util.module_from_spec(spec); sys.modules[spec.name] = dev; spec.loader.exec_module(dev)
    return dev


def engine_pin():
    dev = dev_module(); context = dev.ProjectContext(); p = dev.resolve_godot(context).resolve()
    assert p == (ROOT / '.tools/Godot.app/Contents/MacOS/Godot').resolve()
    r = row(p); assert r['sha256'] == ENGINE_SHA and r['bytes'] == 351312912 and r['mode'] == 0o755
    return r


def prepare():
    ready = json.loads((HERE / 'CORRECTNESS-CLOSED.json').read_text())
    assert ready['root_selected_for_timing'] is True and ready['candidate_route_sha256'] == ROUTE_SHA['candidate'] and ready['candidate_protocol_sha256'] == PROTOCOL_SHA['candidate'] and ready['helper_sha256'] == HELPER_SHA
    for record in ready['closed_correctness_results']:
        result = ROOT / record['path']; assert sha(result) == record['sha256']; value = json.loads(result.read_text())
        assert value.get('returncode', value.get('exit_code')) == 0 and not value.get('exception') and not value.get('closure_error')
        assert value.get('diagnostics', []) == record['retained_diagnostics']
        assert not record['retained_diagnostics'] or record['root_diagnostic_qualification']
        for key, expected in record['required_result_fields'].items(): assert value.get(key) == expected, key
        stream = ROOT / record['raw_log']['path']; assert sha(stream) == record['raw_log']['sha256']
        if record.get('required_footer'): assert record['required_footer'] in stream.read_text()
    assert ready['closed_correctness_results'] and ready['required_import_closed'] is True
    assert sha(ROOT / HELPER) == HELPER_SHA
    """One source bank for both variants, created only with baseline selected."""
    assert not (HERE / 'pair.json').exists() and not (HERE / 'inputs').exists()
    assert sha(ROOT / ROUTE) == ROUTE_SHA['baseline'] and sha(ROOT / PROTOCOL) == PROTOCOL_SHA['baseline']
    assert sha(ROOT / CANDIDATE) == ROUTE_SHA['candidate'] and sha(ROOT / CANDIDATE_PROTOCOL) == PROTOCOL_SHA['candidate']
    assert shutil.disk_usage(HERE).free >= 256 * 1024 * 1024
    seeds = [SCRIPT[6:], str((HERE / 'tools.py').relative_to(ROOT)),
             str((HERE / 'README.md').relative_to(ROOT)), str((HERE / 'fixture.patch').relative_to(ROOT)),
             str((HERE / 'CORRECTNESS-CLOSED.json').relative_to(ROOT)),
             'scripts/dev/dev.py', 'project.godot', '.cinder/local.json',
             '.godot/global_script_class_cache.cfg', 'data/campaign/registry.json',
             'data/design/difficulty_profiles.json', 'data/design/player_equipment.json',
             ROUTE, PROTOCOL, HELPER, '.cinder/a1-l3-stage-source/campaign.json',
             'scenes/acts/act1/a1_l3.tscn', 'scripts/acts/act1/mushroom_caverns_full.gd']
    seen, todo = set(), seeds[:]
    while todo:
        relative = todo.pop(); p = ROOT / relative
        assert p.is_file(), p
        if relative in seen: continue
        seen.add(relative)
        if p.suffix in {'.gd', '.tscn', '.tres', '.json', '.cfg'}:
            for child in re.findall(r'res://([^\s"\'\)]+)', p.read_text()):
                if (ROOT / child).is_file(): todo.append(child)
    uid_rows = uids(); seen.update(r['path'] for r in uid_rows)
    rows = []
    for relative in sorted(seen):
        p = ROOT / relative; archived = HERE / 'inputs' / relative
        archived.parent.mkdir(parents=True, exist_ok=True); subprocess.run(['/bin/cp', '-c', '-p', str(p), str(archived)], check=True)
        r = row(p); r['archive'] = str(archived.relative_to(HERE)); rows.append(r)
    candidate = HERE / 'candidate-route.gd.txt'; shutil.copy2(ROOT / CANDIDATE, candidate)
    candidate_protocol = HERE / 'candidate-protocol.gd.txt'; shutil.copy2(ROOT / CANDIDATE_PROTOCOL, candidate_protocol)
    value = {'prepared_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'files': rows,
             'uids': uid_rows, 'engine': engine_pin(), 'candidate': row(candidate), 'candidate_protocol': row(candidate_protocol), 'correctness': ready, 'seeds': seeds,
             'scope': 'Explicit/literal/global-class-cache bounded resources and all active UID bytes; one shared source bank, only Route/Protocol variants differ; helper present/identical in both. Not a complete dynamic/import graph.'}
    (HERE / 'pair.json').write_text(json.dumps(value, indent=2) + '\n')
    verify('baseline'); print(json.dumps({'prepared': True, 'files': len(rows), 'uids': len(uid_rows), 'pair_sha256': sha(HERE / 'pair.json')}))


def verify(variant):
    pair = json.loads((HERE / 'pair.json').read_text())
    assert variant in ROUTE_SHA and sha(ROOT / PROTOCOL) == PROTOCOL_SHA[variant] and sha(ROOT / HELPER) == HELPER_SHA
    assert row(ROOT / pair['candidate']['path']) == pair['candidate'] and row(ROOT / pair['candidate_protocol']['path']) == pair['candidate_protocol']
    for r in pair['files']:
        archive = HERE / r['archive']; expected = {k: r[k] for k in ['path', 'bytes', 'sha256', 'mode']}
        assert archive.stat().st_size == r['bytes'] and sha(archive) == r['sha256'] and archive.stat().st_mode & 0o777 == r['mode'], archive
        p = ROOT / r['path']; actual = row(p)
        if r['path'] in [ROUTE, PROTOCOL]:
            candidate_row = pair['candidate'] if r['path'] == ROUTE else pair['candidate_protocol']
            wanted = candidate_row if variant == 'candidate' else expected
            variant_sha = ROUTE_SHA[variant] if r['path'] == ROUTE else PROTOCOL_SHA[variant]
            assert actual['sha256'] == variant_sha == wanted['sha256'] and actual['bytes'] == wanted['bytes'] and actual['mode'] == r['mode'], p
        else: assert actual == expected, p
    assert uids() == pair['uids'] and engine_pin() == pair['engine']
    return pair


def freeze(tag, variant, mode):
    assert re.fullmatch('[a-z0-9-]+', tag) and mode in {'parse', 'measure'}
    pair = verify(variant); target = HERE / 'jobs' / tag; assert not target.exists(); target.mkdir(parents=True)
    manifest = {'tag': tag, 'variant': variant, 'mode': mode, 'pair_sha256': sha(HERE / 'pair.json'),
                'route_sha256': ROUTE_SHA[variant], 'protocol_sha256': PROTOCOL_SHA[variant], 'helper_sha256': HELPER_SHA, 'source_count': len(pair['files']), 'uids': pair['uids'], 'scope': pair['scope']}
    (target / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({'frozen': tag, 'variant': variant, 'mode': mode, 'manifest_sha256': sha(target / 'manifest.json')}))


def decode_exact(path):
    raw = path.read_bytes(); assert len(raw) <= 8 * 1024 * 1024
    def unique(pairs):
        result = {}
        for key, value in pairs:
            assert key not in result; result[key] = value
        return result
    def reject_constant(value): raise AssertionError('Nonfinite JSON constant: ' + value)
    e = json.loads(raw, object_pairs_hook=unique, parse_constant=reject_constant); assert type(e) is dict and set(e) == {'api_revision', 'schema_version', 'value'} and e['api_revision'] == 'exact-json-1' and type(e['schema_version']) is int and e['schema_version'] == 1
    budget = [262144]
    def dec(n, depth=0):
        budget[0] -= 1; assert budget[0] >= 0 and depth <= 64 and isinstance(n, list) and n and type(n[0]) is str
        kind = n[0]
        if kind == 'null': assert len(n) == 1; return None
        assert len(n) == 2; v = n[1]
        if kind == 'boolean': assert type(v) is bool; return v
        if kind == 'string': assert type(v) is str; return v
        if kind == 'integer':
            assert type(v) is str and re.fullmatch(r'-?(?:0|[1-9][0-9]*)', v)
            x = int(v); assert str(x) == v and abs(x) <= 9007199254740991; return x
        if kind == 'float64':
            assert type(v) is str and re.fullmatch('[0-9a-f]{16}', v)
            x = struct.unpack('<d', bytes.fromhex(v))[0]; assert math.isfinite(x); return x
        assert isinstance(v, list) and len(v) <= 16384
        if kind == 'array': return [dec(x, depth + 1) for x in v]
        assert kind == 'dictionary'; result = {}; keys = []
        for entry in v:
            assert isinstance(entry, list) and len(entry) == 2 and type(entry[0]) is str and entry[0] not in result
            keys.append(entry[0]); result[entry[0]] = dec(entry[1], depth + 1)
        assert keys == sorted(keys); return result
    return dec(e['value'])


def observed_dictionary(value, required=None):
    """Unwrap only an explicitly expected native Dictionary. Never normalize keys."""
    assert type(value) is dict and set(value) == {'native_type', 'entries'} and value['native_type'] == 'Dictionary'
    assert type(value['entries']) is list and len(value['entries']) <= 16384
    result = {}
    for entry in value['entries']:
        assert type(entry) is list and len(entry) == 2 and type(entry[0]) is str and entry[0] not in result
        result[entry[0]] = entry[1]
    if required is not None: assert set(result) == set(required)
    return result


def exact_same(a, b):
    if type(a) is not type(b): return False
    if type(a) is float: return struct.pack('<d', a) == struct.pack('<d', b)
    if type(a) is list: return len(a) == len(b) and all(exact_same(x, y) for x, y in zip(a, b))
    if type(a) is dict: return set(a) == set(b) and all(exact_same(a[k], b[k]) for k in a)
    return a == b


def clock_bits(value):
    assert type(value) is float and math.isfinite(value)
    return struct.pack('<d', value).hex()


def events(raw, stage):
    found = []
    for line in raw.splitlines():
        if line.startswith('A1_L3_STAGE '):
            v = json.loads(line.split(' ', 1)[1])
            if v.get('stage') == stage: found.append(v)
    assert len(found) == 1, (stage, len(found)); return found[0]


def witnesses(target, raw):
    trace = events(raw, 'spore_fusion_paused_witness'); decoded = {}; rows = {}
    for key, name, prefix in [('native', 'focused-native.exact.json', 'native'), ('packets', 'complete19-packets.exact.json', 'packet')]:
        p = target / 'observed' / name; record = trace[prefix + '_file']
        assert record['path'] == 'res://' + str(p.relative_to(ROOT)) and record['exact_decoded_and_reencoded'] is True
        assert p.stat().st_size == record['bytes'] == trace[prefix + '_bytes'] and sha(p) == record['sha256'] == trace[prefix + '_sha256']
        decoded[key] = decode_exact(p); rows[key] = row(p)
    packets = decoded['packets']; native = decoded['native']
    assert set(packets) == {'scheduler', 'player', 'actors'} and set(packets['actors']) == ACTORS
    assert set(native) == {'references', 'diagnostics', 'focused_native', 'start_observation', 'running_events', 'scope'} and set(native['references']) == {f'crossed-{i}' for i in range(1, 9)}
    focused = observed_dictionary(native['focused_native'], FOCUSED_KEYS); sources = observed_dictionary(focused['sources'], ACTORS)
    assert focused['paused'] is trace['paused'] is True and focused['menu'] == 'pause'
    assert focused['room_stage'] == trace['room_stage'] == 'active' and focused['beat_index'] == trace['beat_index'] == 2
    assert focused['controller_clock_bits'] == trace['scheduler_clock_bits'] == clock_bits(packets['scheduler']['clock_s'])
    assert focused['player_clock_bits'] == trace['player_clock_bits'] == clock_bits(packets['player']['world_actions']['clock_s'])
    assert packets['player']['resources']['hp'] == trace['hp'] == 100.0 and packets['player']['resources']['shells'] == trace['shells'] == 2
    grounded_differences = []
    for key in sorted(ACTORS):
        source = observed_dictionary(sources[key], SOURCE_KEYS); actor = packets['actors'][key]
        pose, velocity = source['pose'], source['velocity']
        assert type(pose) is dict and set(pose) == {'native_type', 'basis', 'origin'} and pose['native_type'] == 'Transform3D'
        assert type(velocity) is dict and set(velocity) == {'native_type', 'components'} and velocity['native_type'] == 'Vector3'
        assert actor['source_id'] == key and exact_same(actor['motion']['position'], pose['origin']) and exact_same(actor['motion']['velocity'], velocity['components'])
        assert type(source['grounded']) is bool and type(source['disabled']) is bool and type(actor['motion']['grounded']) is bool
        if source['grounded'] is not actor['motion']['grounded']:
            grounded_differences.append({'source_id': key, 'packet_logical_grounded': actor['motion']['grounded'], 'native_is_on_floor': source['grounded'], 'native_collision_disabled': source['disabled'], 'packet_dormant': actor['dormant']})
    rows['grounded_schema_differences'] = grounded_differences
    rows['qualified_scope'] = 'Actual Exact file bytes/hash joined to trace; exact named19 actor packets/native sources,8 Crossed references, paused active boundary, clock bits and pose/velocity joins. Saved logical grounded and native floor contact remain distinct. No arbitrary Script-state or optical Save claim.'
    return rows


def run(tag):
    target = HERE / 'jobs' / tag; m = json.loads((target / 'manifest.json').read_text())
    assert sha(HERE / 'pair.json') == m['pair_sha256']; verify(m['variant'])
    log = target / 'wrapper.log'; result = target / 'result.json'; assert not log.exists() and not result.exists()
    command = [sys.executable, '-B', str(Path(__file__).relative_to(ROOT)), 'engine', tag]
    with log.open('xb') as out:
        child = subprocess.Popen(command, cwd=ROOT, stdout=out, stderr=subprocess.STDOUT); code = child.wait()
    closure_error = ''; evidence_error = ''; observed = {}; interval = {}
    try: verify(m['variant'])
    except Exception as e: closure_error = str(e) or type(e).__name__
    raw_path = target / 'raw.log'; raw = raw_path.read_text(errors='replace') if raw_path.exists() else ''
    combined = log.read_text(errors='replace') + '\n' + raw
    diagnostics = re.findall(r'(?m)^ERROR:|^WARNING:|SCRIPT ERROR|Parse Error|Compile Error|FAIL:|leaked|Orphan StringName|unclaimed', combined)
    footers = re.findall(r'Spore fusion measurement: (\d+) checks, (\d+) failures;', raw)
    # Retain and qualify only this exact known host startup diagnostic. All other
    # errors/warnings remain refusals; this never labels a nonclean process clean.
    known_ca = 'ERROR: Condition "ret != noErr" is true. Returning: ""\n   at: get_system_ca_certificates (platform/macos/os_macos.mm:1035)\n'
    classified = combined.replace(known_ca, '')
    unexpected_diagnostics = re.findall(r'(?m)^ERROR:|^WARNING:|SCRIPT ERROR|Parse Error|Compile Error|FAIL:|leaked|Orphan StringName|unclaimed', classified)
    success = code == 0 and not unexpected_diagnostics and not closure_error
    if m['mode'] == 'measure':
        try:
            assert len(footers) == 1 and int(footers[0][0]) > 0 and int(footers[0][1]) == 0
            observed = witnesses(target, raw); interval = events(raw, 'spore_fusion_interval')
            assert interval['physics_frames'] == 8 and interval['process_frames'] == 1 and interval['actor_identities_unchanged'] is True
            assert abs(interval['player_elapsed_s'] - 8/60) < 1e-10 and abs(interval['scheduler_elapsed_s'] - 8/60) < 1e-10 and interval['wall_us'] > 0
        except Exception as e: evidence_error = str(e) or type(e).__name__; success = False
    value = {'closed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'variant': m['variant'], 'mode': m['mode'], 'returncode': code,
             'command': command, 'wrapper_pid': child.pid, 'successful_scope': success, 'source_and_uids_exact_at_closure': not closure_error,
             'closure_error': closure_error, 'evidence_error': evidence_error, 'diagnostics': diagnostics, 'unexpected_diagnostics': unexpected_diagnostics, 'clean_process': code == 0 and not diagnostics and not closure_error, 'known_host_ca_blocks': combined.count(known_ca), 'footers': footers,
             'manifest_sha256': sha(target / 'manifest.json'), 'pair_sha256': m['pair_sha256'], 'source_count': m['source_count'],
             'streams': [row(p) for p in [log, raw_path] if p.exists()], 'witnesses': observed, 'interval': interval}
    result.write_text(json.dumps(value, indent=2) + '\n'); print(json.dumps(value)); return 0 if success else 1


def engine(tag):
    target = HERE / 'jobs' / tag; m = json.loads((target / 'manifest.json').read_text())
    if m['mode'] == 'measure':
        parses = [json.loads(p.read_text()) for p in (HERE / 'jobs').glob('*/result.json')]
        assert any(r['mode'] == 'parse' and r['variant'] == m['variant'] and r['successful_scope'] and r['pair_sha256'] == m['pair_sha256'] for r in parses), 'Exact same-pair variant needs accepted parse closure; any qualified host diagnostic remains retained'
    dev = dev_module(); context = dev.ProjectContext()
    command = [str(dev.resolve_godot(context)), '--path', str(ROOT), '--headless', '--script', SCRIPT, '--log-file', str(target / 'raw.log')]
    command += ['--check-only'] if m['mode'] == 'parse' else ['--', '--measurement-label=' + tag]
    (target / 'submission.json').write_text(json.dumps({'engine_command': command, 'deadline_s_after_queue_acquisition': 90}, indent=2) + '\n')
    with dev.godot_lock(context.root) as lock:
        assert sha(HERE / 'pair.json') == m['pair_sha256']; verify(m['variant'])
        print('Canonical queue acquired; own90s deadline starts now.', flush=True)
        return dev.run_validation(command, context, lock, 90, detect_godot_errors=True)


def compare(baseline_tag, candidate_tag):
    a = HERE / 'jobs' / baseline_tag; b = HERE / 'jobs' / candidate_tag
    x = json.loads((a / 'result.json').read_text()); y = json.loads((b / 'result.json').read_text())
    assert x['successful_scope'] and y['successful_scope'] and x['mode'] == y['mode'] == 'measure'
    assert x['variant'] == 'baseline' and y['variant'] == 'candidate' and x['pair_sha256'] == y['pair_sha256'] == sha(HERE / 'pair.json')
    for target, closed in [(a, x), (b, y)]:
        assert sha(target / 'manifest.json') == closed['manifest_sha256']
        for record in closed['streams'] + [closed['witnesses']['native'], closed['witnesses']['packets']]:
            assert row(ROOT / record['path']) == record, record['path']
    assert (a / 'observed/complete19-packets.exact.json').read_bytes() == (b / 'observed/complete19-packets.exact.json').read_bytes(), 'Actual complete19/Player/Scheduler packets differ'
    for field in ['physics_frames', 'process_frames', 'player_elapsed_s', 'scheduler_elapsed_s', 'hp_before', 'hp', 'hero_position', 'room_stage', 'beat_index']:
        assert x['interval'][field] == y['interval'][field], field
    na = decode_exact(a / 'observed/focused-native.exact.json'); nb = decode_exact(b / 'observed/focused-native.exact.json')
    assert exact_same(na['references'], nb['references']) and exact_same(na['diagnostics'], nb['diagnostics'])
    assert exact_same(na['running_events'], nb['running_events']), 'Ordered running event receipts differ'
    fa = observed_dictionary(na['focused_native'], FOCUSED_KEYS); fb = observed_dictionary(nb['focused_native'], FOCUSED_KEYS)
    sa = observed_dictionary(fa['sources'], ACTORS); sb = observed_dictionary(fb['sources'], ACTORS)
    for source in ACTORS:
        xa = observed_dictionary(sa[source], SOURCE_KEYS); xb = observed_dictionary(sb[source], SOURCE_KEYS)
        for key in SOURCE_KEYS - {'node_id', 'script_id', 'collision_id', 'shape_id'}:
            assert exact_same(xa[key], xb[key]), (source, key)
    nonidentity = FOCUSED_KEYS - {'shell_id','shell_script','level_id','level_script','hero_id','hero_script','controller_id','controller_script','sources','camera_pose','camera_focus'}
    for key in nonidentity: assert exact_same(fa[key], fb[key]), key
    ba = observed_dictionary(na['start_observation']); bb = observed_dictionary(nb['start_observation'])
    for key in set(ba) - {'camera_pose','camera_focus'}: assert exact_same(ba[key], bb[key]), ('start',key)
    camera_start_equal = all(exact_same(ba[k],bb[k]) for k in ['camera_pose','camera_focus'])
    camera_end_equal = all(exact_same(fa[k],fb[k]) for k in ['camera_pose','camera_focus'])
    result = {'camera_start_equal': camera_start_equal, 'camera_end_equal': camera_end_equal, 'whole_native_equality_claimed': False, 'matched_native_nonidentity_projection': camera_start_equal and camera_end_equal, 'ordered_running_events_equal': True, 'baseline': baseline_tag, 'candidate': candidate_tag, 'baseline_wall_us': x['interval']['wall_us'], 'candidate_wall_us': y['interval']['wall_us'],
              'single_pair_relative_change_percent': 100*(y['interval']['wall_us']/x['interval']['wall_us']-1),
              'complete19_packet_bytes_equal': True, 'pair_source_rule': 'Only selected Route/Protocol differ; helper and all other frozen inputs/active UIDs are identical.',
              'scope': 'One same-fixture uninstrumented pair; native instance identities differ and native packets are not asserted identical. Camera differences are explicit; no whole-native equality, sustained FPS, repeatability, causal codec gain or camera/Save repair claim.'}
    output = HERE / 'comparison.json'; assert not output.exists(); output.write_text(json.dumps(result, indent=2) + '\n'); print(json.dumps(result))


if __name__ == '__main__':
    action = sys.argv[1]
    if action == 'prepare': prepare()
    elif action == 'freeze': freeze(*sys.argv[2:5])
    elif action == 'run': sys.exit(run(sys.argv[2]))
    elif action == 'engine': sys.exit(engine(sys.argv[2]))
    elif action == 'compare': compare(*sys.argv[2:4])
    else: raise SystemExit('Use prepare | freeze TAG baseline|candidate parse|measure | run TAG | compare BASELINE_TAG CANDIDATE_TAG')
