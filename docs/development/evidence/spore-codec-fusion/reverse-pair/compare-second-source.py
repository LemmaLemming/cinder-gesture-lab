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
    output = HERE / 'comparison-second.json'; assert not output.exists(); output.write_text(json.dumps(result, indent=2) + '\n'); print(json.dumps(result))
