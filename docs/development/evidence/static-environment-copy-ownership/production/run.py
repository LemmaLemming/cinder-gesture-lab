"""Focused canonical A3-L5 registration through the shared Godot queue."""
from pathlib import Path
import contextlib
import datetime
import hashlib
import importlib.util
import json
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PHASES = {"spore-native"}
if len(sys.argv) != 2 or sys.argv[1] not in PHASES:
    raise SystemExit("Pass one named registration phase")
phase = sys.argv[1]
out = HERE / phase
out.mkdir(exist_ok=False)
spec = importlib.util.spec_from_file_location("a3_registration_dev", ROOT / "scripts/dev/dev.py")
dev = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = dev
spec.loader.exec_module(dev)
context = dev.ProjectContext()

def snapshot():
    selected = [ROOT / "project.godot", ROOT / "scripts/dev/dev.py", Path(__file__), ROOT / "tests/scheduler_spore_source_smoke.gd"]
    for folder in ("scripts", "tests/fixtures"):
        selected.extend(p for p in (ROOT / folder).rglob("*") if p.is_file() and p.suffix in {".gd", ".uid"})
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(selected))}

def save(name, value):
    (out / name).write_text(json.dumps(value, indent=2) + "\n")

class Tee:
    def __init__(self, original, log): self.original, self.log = original, log
    def write(self, value):
        self.log.write(value)
        return self.original.write(value)
    def flush(self): self.log.flush(); self.original.flush()

script = "res://tests/scheduler_spore_source_smoke.gd"
command = [str(dev.resolve_godot(context)), "--path", str(ROOT), "--headless", "--log-file", str(out / "engine.log"), "--script", script]

before = snapshot()
save("source-before.json", before)
result = {"phase": phase, "command": command, "submitted_at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "engine_timeout_seconds": 90}
save("lifecycle.json", result)
with (out / "raw.log").open("w") as log, contextlib.redirect_stdout(Tee(sys.stdout, log)), contextlib.redirect_stderr(Tee(sys.stderr, log)):
    code = 2
    try:
        with dev.godot_lock(context.root) as lock:
            result["queue_acquired_at"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
            save("lifecycle.json", result)
            print("Canonical queue acquired; owned engine deadline starts now.", flush=True)
            started = time.monotonic()
            code = dev.run_validation(command, context, lock, 90, detect_godot_errors=True)
            result["engine_elapsed_seconds"] = time.monotonic() - started
    except Exception as error:
        result["runner_error"] = repr(error)
        print("Runner error:", repr(error), flush=True)
    finally:
        after = snapshot()
        save("source-after.json", after)
        result.update(returncode=code, closed_at=datetime.datetime.now(datetime.timezone.utc).isoformat(), selected_inputs=len(before), changed_inputs=[p for p in sorted(before.keys() | after.keys()) if before.get(p) != after.get(p)])
        save("result.json", result)
sys.exit(code)
