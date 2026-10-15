# Inert targeted encounter-arrangement runner

Prepared authoring tool only. No phase has been run, no engine/import/UID action has occurred, and no test assertions or source closure are claimed. Root must review and promote the proposed helper/test, then supply an explicit sealed manifest; the template is deliberately unusable.

Run one phase at a time from the integration checkout:

```sh
python3 .cinder/encounter-arrangement-native-20261015/run.py selected-import --manifest ROOT_SEALED_MANIFEST.json
python3 .cinder/encounter-arrangement-native-20261015/run.py selected-parse --manifest ROOT_SEALED_POST_IMPORT_MANIFEST.json
python3 .cinder/encounter-arrangement-native-20261015/run.py selected-native --manifest ROOT_SEALED_POST_IMPORT_MANIFEST.json
```

Root's manifest must set `sealed: true`, identify `sealed_by`, and pin lowercase SHA256 values for exactly the helper, test, canonical dev module, project settings, this runner and the already imported `snapshot_codec.gd` source/UID that the actual proposal preloads. The current proposal test also preloads `res://scripts/campaign/exact_json.gd`; explicitly pin that already imported source/UID too (omit that pair only if the promoted test no longer references it). There is no dependency expansion. The parser phase requires a literal helper preload in the test. Existing helper/test UIDs must be pinned; absent ones may use `null` only for selected-import. After import, Root seals the genuine UID hashes from the closed named source map before parser/native runs. No UID is fabricated here.

Each invocation uses canonical `dev.ProjectContext`, `godot_lock` and `run_validation`. The 180-second engine deadline starts after queue acquisition. The dev function alone owns, stops and waits its direct child; this wrapper never signals another process, signals a process group, deletes a lock or bypasses the queue. Canonical dev encapsulates its child PID, so no PID is invented in the lifecycle record. Import uses the queued whole-project editor import; its evidence proves only the small named source/UID subset, and does not claim global engine metadata stayed unchanged.

The sealed named sources are snapshotted before queuing, at lock acquisition and after the owned child terminates. Any queued drift prevents execution. Any later source/UID change fails closure except additions of the two named new UIDs during import. No removal or changed existing UID is allowed. A phase has a unique output directory containing command, queue, lifecycle, raw and engine logs, explicit source maps/delta, result and a hash index written after closure. A preflight or failed child remains a closed failed result; a lifecycle closure alone is not test success.

## Native report contract agreed with the helper author

Only the native child receives `CINDER_ENCOUNTER_ARRANGEMENT_REPORT`, set to its unique absolute `native-report.json` path. The test must save plain UTF-8 JSON there (at most 512 KiB; no nonfinite values, duplicate keys or unsafe integer instance IDs), including:

```json
{
  "schema_version": 1,
  "checks": 1,
  "failures": 0,
  "first_failure": {},
  "rows": [{"check": 1, "ok": true, "label": "actual assertion label"}],
  "complete": true,
  "success": true,
  "source_observations_before": {
    "res://scripts/combat/encounter_arrangement.gd": "actual helper SHA256",
    "res://tests/encounter_arrangement_smoke.gd": "actual test SHA256"
  },
  "source_observations_after": {
    "res://scripts/combat/encounter_arrangement.gd": "actual helper SHA256",
    "res://tests/encounter_arrangement_smoke.gd": "actual test SHA256"
  }
}
```

The example describes schema only; it is not executed evidence or a promised assertion count. Every actual assertion must have a row. The test prints exactly one of each line after writing the completed report, using its actual count, absolute path and report-byte SHA256:

```text
CINDER_ENCOUNTER_ARRANGEMENT_REPORT path=<absolute report path> sha256=<report-byte SHA256>
Encounter arrangement smoke: <actual count> checks/<actual failures> failures; complete=<true|false>; pure metadata only
```

The runner verifies `checks == rows.size`, `failures == actual false rows`, and `first_failure` equal to the full first false row or `{}`. It checks actual boolean `complete` and `success == complete && failures == 0`. Both before/after helper/test observations must equal the seal. Failure reports and original logs remain evidence even if the owned child fails.

Runner success requires the actual canonical owned-child return code 0, a clean uniquely named engine log, complete passing structured assertions, both printed joins and source observations equal to the Root seal. The helper author agreed this exact protocol; Root must review the actual promoted test before use. Preparation does not infer its assertion count or source closure.

The proposal helper/test were inspected as authoring text after agreeing the protocol; their actual direct dependencies are the two named sources above. No engine, parser, import or native phase was run. A host AST syntax parse of this Python file is preparation validation only.

This pure-helper suite cannot accept a level or close the nineteen-level Challenge arrangement gap. Owner consumer acknowledgments and legacy integration remain separate work; no full route or campaign playthrough is introduced as a gate.
