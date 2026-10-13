# Paired collision traversal measurement

SOURCE ONLY: prepared without engine execution, runtime selection, freezer bank,
Git changes or additional campaign acceptance. Root owns all execution below.
The exact candidate is the two-line early type filter, Route SHA256
`b266f93d04d1f04a33bc32cbd64205c73f2985b559327f828e877963d6767d9c`;
baseline is `2bdfd3ea6997beceb0d5d26eb27e8520214872b0e81e1d7f8039afbf6d53b30a`.
Both require uninstrumented Protocol `a01b5481` and the pinned Godot executable.

The fixture keeps genuine original CP2 -> actual GUI Continue/Resume -> one
explicit TEST Hero relocation -> native Crossed activation -> one actual
physics/process await pair. That pair must advance eight physics frames,
one process frame and8/60 seconds in both Player/Scheduler, with identical
actor identities and HP within each run. Only wall microseconds surround the
await pair. Every profiler/sink/counter and associated assertion is removed.

Actual focused-native observation precedes complete19/Player/Scheduler snapshot
writers after public Pause. Both Exact strings are persisted as new files
outside timing, decoded/re-encoded by Godot, and byte/hash joined on the host.
The host correctly unwraps the native observation's tagged Dictionary at the
expected two levels; it does not treat it as plain JSON or normalize StringName
keys. Original camera/encounter diagnostic refusals are observed, not repaired.

## Commands for Root

With production baseline Route/Protocol selected and other shared files frozen:

```sh
python3 -B .cinder/collision-traversal-measure/tools.py prepare
python3 -B .cinder/collision-traversal-measure/tools.py freeze baseline-parse baseline parse
python3 -B .cinder/collision-traversal-measure/tools.py run baseline-parse
python3 -B .cinder/collision-traversal-measure/tools.py freeze baseline-window baseline measure
python3 -B .cinder/collision-traversal-measure/tools.py run baseline-window
```

Root then selects only its reviewed candidate Route at the canonical path,
preserving the original mode. This runner never selects/restores files.

```sh
python3 -B .cinder/collision-traversal-measure/tools.py freeze candidate-parse candidate parse
python3 -B .cinder/collision-traversal-measure/tools.py run candidate-parse
python3 -B .cinder/collision-traversal-measure/tools.py freeze candidate-window candidate measure
python3 -B .cinder/collision-traversal-measure/tools.py run candidate-window
python3 -B .cinder/collision-traversal-measure/tools.py compare baseline-window candidate-window
```

Root closes its own handles and preserves/restores the selected source according
to its reviewed decision. Do not change any other input between jobs, integrate
Act2 fixtures/imports mid-pair, remove locks, restart a live job or overwrite an
existing tag. A failed measurement stays failed; do not enlarge frame/clock
bounds to make a new sample pass. Every child uses the canonical dev.py queue
and its own90-second bound after lock acquisition, with85-second event-loop
watchdog. Needed display/user:// access follows the same authorization as prior
headless canonical jobs.

`prepare` freezes one shared source bank rather than duplicating it per run.
It follows explicit/literal resources and the global-class cache, plus all
active UID bytes/modes, isolated local config, original save, real executable
and selected runtime. This is a bounded dependency set, not a complete dynamic
asset/import graph. Each job verifies current and archived sources before queue
execution and after closure; only the exact Route variant can differ. The
candidate itself is retained in the bank. Four small job manifests reference
the same immutable pair.

`compare` requires successful original closures and intact logs/witness files,
identical actual complete19/Player/Scheduler Exact packets and equal native
clock/frame/HP/pose observations. It reports one-pair elapsed-time change.
Fresh native instance IDs differ between processes, so the focused-native files
are independently verified and retained, not asserted byte-identical. One pair
cannot establish repeatability, sustainedFPS, causal gain, camera/Save repair,
full-route completion, or new level acceptance. Separate differential collision
controls establish the candidate's correctness; use their canonical wrapper.

Static preparation checks: Python AST passes; host decoding of the existing
profile2 actual focused-native witness finds8references/19sources/genuine pause;
local stage copy is byte-identical to the current-registry source; measured
block is only timer/await pair/timer; native-before-packet ordering retained.
GDScript parsing and the new pair remain unexecuted at handoff.
