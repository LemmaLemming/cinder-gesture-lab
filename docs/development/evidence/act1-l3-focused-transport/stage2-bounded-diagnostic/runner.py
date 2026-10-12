from pathlib import Path
import json, hashlib, subprocess, sys, datetime, threading, queue, time, signal, os

r = Path.cwd()
manifest = r / '.cinder/a1-l3-stage2-source/manifest.json'
m = json.loads(manifest.read_text())
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
def verify():
    for row in m['files']:
        for p in [r / row['path'], manifest.parent / row['archived_path']]:
            assert p.stat().st_size == row['bytes'] and sha(p) == row['sha256'], str(p)
verify()
log = r / '.cinder/a1-l3-stage2-wrapper.log'
assert not log.exists()
cmd = [sys.executable, 'scripts/dev/dev.py', 'engine', '--path', '.', '--headless', '--script', 'res://.cinder/a1-l3-stage-diagnostic2.gd']
started = datetime.datetime.now(datetime.timezone.utc).isoformat()
events = queue.Queue()
native_pid = None
native_started = None
host_bound = None
with log.open('xb') as out:
    child = subprocess.Popen(cmd, cwd=r, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    def read():
        for line in iter(child.stdout.readline, b''):
            out.write(line)
            out.flush()
            if line.startswith(b'A1_L3_STAGE '):
                events.put(json.loads(line[len(b'A1_L3_STAGE '):]))
        events.put(None)
    reader = threading.Thread(target=read, daemon=True)
    reader.start()
    while child.poll() is None:
        try:
            event = events.get(timeout=0.1)
        except queue.Empty:
            event = None
        if event is not None and native_pid is None:
            native_pid = event['engine_pid']
            native_started = time.monotonic()
            print(json.dumps({'native_pid': native_pid, 'stage': event['stage'], 'host_bound_seconds_after_first_native_trace': 120}), flush=True)
        if native_started is not None and host_bound is None and time.monotonic() - native_started >= 120:
            actual = subprocess.check_output(['ps', '-p', str(native_pid), '-o', 'command='], text=True).strip()
            parent = subprocess.check_output(['ps', '-p', str(native_pid), '-o', 'ppid='], text=True).strip()
            expected = str(r / '.tools/Godot.app/Contents/MacOS/Godot') + ' --path . --headless --script res://.cinder/a1-l3-stage-diagnostic2.gd'
            assert actual == expected and int(parent) == child.pid
            host_bound = {'native_pid': native_pid, 'wrapper_pid': child.pid, 'native_wall_seconds': time.monotonic() - native_started, 'actual_command': actual, 'action': 'SIGTERM only the exact owned native child at its120second diagnostic host bound; no other engine/queue/lock change'}
            os.kill(native_pid, signal.SIGTERM)
    code = child.wait()
    reader.join()
verify()
raw = log.read_bytes()
v = {'schema_version': 1, 'started_at': started, 'closed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'command': cmd, 'child_pid': child.pid, 'native_pid': native_pid, 'returncode': code, 'host_bound': host_bound, 'source_manifest': str(manifest.relative_to(r)), 'source_manifest_sha256': sha(manifest), 'source_count': len(m['files']), 'original_archive_current_match': True, 'wrapper_log': str(log.relative_to(r)), 'wrapper_log_bytes': len(raw), 'wrapper_log_sha256': sha(log), 'scope': 'Narrow genuine CP2 fresh quiet Continue and exactly one supported TEST Hero placement, at most5 physics/process await pairs with stage/provider/containment/clock traces. In-memory TEST accepted L3 metadata; actual canonical registry9 remains unchanged. Current Attempts6701 only expands saved availability; actual Full/Route/Actor/world/guards unchanged. No acceptance/earned-route/verified root-cause/performance claim.'}
(r / '.cinder/a1-l3-stage2-result.json').write_text(json.dumps(v, indent=2) + '\n')
print(json.dumps(v), flush=True)
for line in raw.decode('utf-8', 'replace').splitlines():
    if 'FAIL:' in line or 'SCRIPT ERROR' in line or 'Parse Error' in line or line.startswith('A1-L3 stage diagnostic:'):
        print(line)
sys.exit(1 if any(tag in raw.decode('utf-8', 'replace') for tag in ['SCRIPT ERROR', 'Parse Error', 'FAIL:']) else code)
