# Fresh-world restore evidence

This archive preserves actual closed Root jobs and their exact tested code. [INDEX.json](INDEX.json) pins raw logs, results, manifests, deduplicated source objects and the local full-bank locations. Original files and banks were not changed.

| Job | Actual closure | Native footer / parser scope | Evidence |
| --- | --- | --- | --- |
| campaign-shell-native-01 | CLOSED_NATIVE_NONPASS | Campaign shell smoke: 55 checks, 1 failures (TEST ONLY live fixtures) | [raw](jobs/campaign-shell-native-01/raw.log) |
| physics-core-native-01 | CLOSED_NATIVE_PASS | Restore candidate physics smoke: 96 checks, 0 failures (TEST ONLY core paused native floor) | [raw](jobs/physics-core-native-01/raw.log) |
| physics-core-parse-01 | CLOSED_PARSE_CLEAN | clean parser process; no native checks | [raw](jobs/physics-core-parse-01/raw.log) |
| physics-startup-native-01 | CLOSED_NATIVE_PASS | Restore candidate startup Retry smoke: 21 checks, 0 failures (TEST ONLY canceled-load operation boundary) | [raw](jobs/physics-startup-native-01/raw.log) |
| restore-legacy-native-01 | CLOSED_NATIVE_PASS | Restore candidate smoke: 71 checks, 0 failures (TEST ONLY native constructor/Shell paths) | [raw](jobs/restore-legacy-native-01/raw.log) |
| restore-legacy-parse-01 | CLOSED_PARSE_NONCLEAN | nonclean parser; original errors retained | [raw](jobs/restore-legacy-parse-01/raw.log) |

The original legacy parse returned 0 while recording two log-file-opening errors, so it remains nonclean. The original Shell job remains 55 checks / 1 failure. Its unavailable-next-scene assumption was stale: the frozen setup replaced L1/L2/O1 but its frozen registry already accepted A1-L3. That cause is supported by source review; the raw log does not record installed L3 state. Corrected Shell and persistence jobs are excluded until an actual result exists. Pending evidence is not a pass.

Agent02's `db87eb67` finding is retained as its original unexecuted source trace. The narrow startup cancellation correction is source-only at its seal; the later actual startup 21/0 job proves the specific canceled-load boundary, visible retained queued Retry failure, unchanged saved file/native cleanup and recovery after reopening the original file and public Continue. It does not establish in-place failed-operation recovery, whole native-lunge restoration, optical acceptance or campaign acceptance.

Exact tested Shell, Level, test code and runner snapshots are SHA256 objects, deduplicated by content. Historical draft comments remain literal. The per-job index maps each original tested path to its immutable object and records the actual source version tested.

Full banks remain locally under `.cinder/fresh-world-floor-review/jobs/<tag>/inputs`, with their complete original manifests pinned here. Unchanged inputs reference independently hash-matched blobs at Git base `35dce275366d6f497c3319745f04049f5d239e48`. Huge assets/banks, machine `.cinder/local.json`, global class cache and engine binaries are excluded from the portable subset. Their manifest hashes remain recorded; this archive is not a complete portable replay proof. No engine/import/production/Git action was performed while archiving.
