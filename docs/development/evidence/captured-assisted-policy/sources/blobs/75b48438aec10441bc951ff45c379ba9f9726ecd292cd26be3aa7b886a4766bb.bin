# Private captured-Assisted validation runner

Prepared for Root review against ROOT_COHORT_PROMOTION.json `66e5225e1d28213519d2fa2ad7635374f605e7667c7056f679fffa8cbd4a7f06`. This capsule has not been invoked: no preflight, seal, import, parser or engine run occurred during preparation. Root already promoted the cohort; this runner performs no promotion. The two-slot source supplement review remains Root's separate dependency.

Run from the primary checkout. Each command creates a new preserved output directory under this directory. There is no default suite or automatic successor phase.

```text
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py seal --promotion .cinder/captured-assisted-policy-audit-20261015/ROOT_COHORT_PROMOTION.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py import --seal /absolute/path/to/run-seal-.../seal.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py parse common --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py parse legacy --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py parse authored --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py parse shell --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py native common --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py native legacy --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py native authored --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py native shell --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
```

These are separate explicitly chosen commands, not a requested all-suite rerun. Root selects the directly affected cases. Use the actual successful closed seal printed by that invocation, not the placeholder. A referenced seal must join its own CLOSED0/passed result and post-log-close evidence index. A seal file left by a subsequently failed phase is refused. Necessary import writes a new fixed-after-import seal only after its owned validation returns zero and all named custody checks pass.

Optional brief native portrait is **one Shell case only**:

```text
python3 .cinder/captured-assisted-policy-audit-20261015/validation-prepare/run.py native shell --portrait --seal /absolute/path/to/run-import-.../fixed-after-import-seal.json
```

This omits headless, passes only native `--portrait`, and creates an exclusive new `<unique-output>/portraits/` directory. The child receives CINDER_CAPTURED_PARENT_PORTRAITS only for this case. Actual PNG signature, IHDR340x736, SHA, path and boundary flags join the report in a separate portrait-file-verification.json. This verifies files and receipts only; Root must separately inspect actual pixels. The runner never self-escalates graphical or user Store sandbox access.

## Exact custody and report contracts

INPUT_SPEC lists **175 explicit observations** including this four-file capsule. It deduplicates original45 named producer inputs, Additional PREPARATION37, the twenty-two promoted candidate paths, their exact private donors, the final promotion/audit/two-slot provenance, selected direct test/Main/parent/room/presentation/configuration inputs and their named existing UID sidecars. These are named observations, not a recursive dependency closure or global UID census. The known absent historical framing_candidate_extension.gd remains excluded; the old parent-phase test is a source observation, never an execution selector.

Only the six new GDScript sidecars listed in Root's promotion manifest may be absent before import. Import permits only those observed null-to-present transitions and requires all six to exist afterward. Existing selected UIDs and every named source remain fixed. Later parse/native phases require exact fixed-after-import observations. No UIDs are invented. Unselected global editor/import behavior is not audited by this subset.

The final promotion manifest pins every actual and private donor SHA/byte length. Normalized GDScript header comments must retain exact noncomment lines; other paths must remain byte-identical to their donor. The manifest itself, candidate CHANGE_AUDIT and final two-slot source records are named/pinned. The early unexecuted runner/spec are retained under unexecuted-pre-release-draft; they are not executable readiness evidence.

All engine calls use canonical scripts/dev/dev.py ProjectContext, godot_lock and run_validation. Direct-child timeouts start after lock acquisition: import180s, each parser120s, common/legacy/authored native180s, Shell native360s. Authored's source watchdog is150s; Shell's is300s. No queue-wait timeout, lock deletion, process search/kill, process-priority change or heavy parallel launch exists.

Each valid phase creates original command/queue/result/raw/engine records, fixed source observations and actual source-byte blobs before comparison at preflight/before queue/at lock/after canonical child return/runner close, plus a recursive **output-only** index after raw closes. Source bytes are deduplicated within each phase, not across unrelated evidence banks. A refused/failed phase closes with passed=false and keeps actual partial native report/PNG/raw files; CLOSED describes the runner, not success. Canonical API return is preserved separately and may be a synthetic timeout/script-error result rather than a separate OS exit code. A launch-attempt flag alone never proves a child started.

- **common / legacy:** actual inherited PASS/FAIL lines and exactly one existing end footer must join nonempty counters and owned validation zero. These native scripts have no structured report, row array or complete boolean. The runner explicitly records that limitation and invents none.
- **authored:** CINDER_CAPTURED_AUTHORED_CONTROL_REPORT is an absolute unique native-report.json path in the owned child only. Actual plain JSON rows/checks/failures/complete/success, ordinal and false-row counts join the literal report SHA/path/footer and terminal result. No source-map field is invented.
- **Shell:** CINDER_CAPTURED_PARENT_SHELL_REPORT plus CINDER_CAPTURED_ADDITIONAL_SOURCES are scoped to the owned child. Same row/boolean/footer/SHA joins, plus exact native source-before/after equality to all175 fixed observations, actual opaque Exact receipt strings and explicit portrait request/PNG receipts. Exact receipt strings are retained without generic decoding/normalization.
- Actual report first_failure is checked only if the native report supplies it; otherwise the runner records its absence and separately observes the first actual failed row. Neither structured source currently supplies that field.

Native report validation still runs after a nonzero canonical return when source custody reaches that point, preserving failure observations. A zero child return alone never passes a native phase. Host/editor/script/audio ERROR/WARNING lines remain in raw/engine files and are listed separately; zero exit does not label them clean. There are no Python asserts, skipped guards, changed native windows, fabricated records or acceptance/consumer/FPS claims.
