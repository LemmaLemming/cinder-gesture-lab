# Observed, locked source-reuse controls

This is a **new offline fixture/runner release**. The frozen `runtime-source-reuse-signature-safe` release remains unchanged. All four runtime candidates are copied byte-exact from that release; no production acceptance, signature, native guard, schema or catalogue value changes belong to this folder. Root has separately adopted those exact runtime hashes. No Godot or GDScript parse result is claimed here.

## Actual observations

The fixture adds a fresh full actual control snapshot before each optimized/original check. Each before/after Exact tagged string must be nonempty, and each control must start from the same actual original unit. Its existing native-ID decimal tags remain diagnostic only; public Player, Scheduler and Playback packets keep their original types and bits.

Every control emits one `AUTHORED_SOURCE_REUSE_OBSERVATION` JSON line containing its mode, optimized/original discriminator, both complete Exact strings, actual callback array, decision/error, getter count and catalogue write error. The strings originate from the actual paused fixture's public/native observations; no donor or synthetic actor envelope supplies them. A reader can decode both Exact strings independently, compare all HP/clock/program/body/renderer/resource fields, and inspect callbacks without relying solely on a printed PASS label. Sixteen modes and two paths produce at most 32 such lines if setup and all receipts succeed. Missing output or empty encoding cannot become observation credit.

Diagnostic limits are two MiB per actual unit, ten MiB per outer JSON line, 128 callbacks of at most 256 UTF8 bytes, and 16 KiB per error. Exceeding them fails the fixture and omits that invalid observation. These are finite test-output limits, **not** new production transport or projection limits. The inherited fixture is still the one native source/full actual Player/Scheduler/Playback control, not a restored actor codec, authored-level or performance proof.

## Canonical lock and restoration

The runner follows the repository's `tests/test_dev_tools.py` importlib loader pattern and imports the **actual hash-pinned `scripts/dev/dev.py`**, with bytecode writes disabled during import. It temporarily wraps that module's `run_child` in memory, then calls its original `main(["engine", ...])` once. It never starts a child dev CLI, obtains a second lock, or invokes Godot independently.

The actual `dev.main` engine path enters `godot_lock` at lines 528–529 and invokes the wrapped `run_child` inside it. The wrapper refuses an absent borrowed lock descriptor or a second child invocation. Only then does it reverify the frozen release/live candidates, capture the actual original catalogue **bytes and permission mode**, and write the backup. It passes unchanged argv, context and inherited descriptor to the original `run_child`.

The original native child is observed through an in-memory `Popen` wrapper that forwards every argument unchanged. Its completion is awaited even if its original wait unexpectedly raises. In the callback's `finally`, exact catalogue bytes **and mode** are restored atomically, verified and reported before the callback returns or propagates an exception. Only afterward can `dev.main` unwind its existing lock context. Mode-only drift is restored too; equal bytes alone are insufficient. No native world getter, engine launch path or lock implementation is replaced in future execution.

Catchable SIGINT/SIGTERM requests are deferred during that child/restoration critical section so cleanup does not race a still-running writer. The runner does not force-kill a child and may wait for its bounded fixture to close. Shutdown before lock entry follows ordinary dev behavior. SIGKILL, process/machine loss or failed filesystem restoration can still prevent cleanup; root must recover the retained backup and inspect the catalogue before allowing later readers. This is not a hard-termination guarantee. No concurrency authority derives from a command flag.

## Future invocation and provenance

Root must review this release, retain original transitive sources, and authorize its real catalogue-write interval before executing:

```sh
python3 .cinder/runtime-source-reuse-observed-locked/run_controlled_fixture.py --execute-reviewed-candidates --run-id source-reuse-control1
```

The intended original canonical native arguments remain `engine --headless --verbose --path ROOT --script res://.cinder/runtime-source-reuse-observed-locked/source_reuse_smoke.gd --log-file ABSOLUTE_NATIVE_LOG -- --allow-canonical-catalogue-mutation`. For the default plain run ID, the full pair is root `.cinder/source-reuse-control1.log` and `.cinder/source-reuse-control1-wrapper.log`; root can freeze `.cinder/source-reuse-control1-source` and use its ordinary closure tooling without mirrors. `--run-id` accepts only a bounded plain job name. The runner preserves the actual local runner argv, `dev.main` argv, observed native argv, native PID/exit, locked backup/restore hashes and mode, and full native/wrapper log hashes in separate submission/closure receipts inside this release folder. Tool session and approval provenance remain null unless supplied independently; they are never guessed. `dev.main` exit zero does not establish native correctness; full Script/native diagnostics and emitted observations require independent review.

Existing logs, backup or receipts refuse another execution in this release directory. Root must freeze a new run scope rather than overwrite originals. No observed cost claim or Shared36 archive is generated here.

## Python-only self-check

`self_check.py` tests the runner with the actual imported `dev.main` and `run_child` bodies, but replaces the lock context and native child with explicit **synthetic** implementations. It creates no Godot process and acquires no real lock. Five controls prove ordinary nonzero child completion, unexpected wait interruption/error while the fake child remains live, and permission-only drift all restore exact bytes/mode before the mocked `dev.main` lock exits. They retain the fake child's actual exit separately from dev's caught-error exit 2, interruption exit 130 and an exception that propagates without a dev return. These are Python orchestration controls, not native engine evidence. `self-check.json` records their event order and limitations. The fixture remains unparsed and unexecuted.
