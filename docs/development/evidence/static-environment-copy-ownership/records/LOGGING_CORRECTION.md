# Logging-only correction after first native ownership run

Original queued parser closed0. Original native job closed111 checks/1 failure: all110 pre-existing setup, compilation, comparison, mutation, setting, purity and cleanup assertions passed; only the evidence-write diagnostic failed. Its complete original source/runner/result/log snapshots are preserved under `ownership-native01-failure-source/`, and both original job directories remain byte-identical. Neither original result is rewritten as passed.

The old receipt encoder forwarded native integers verbatim. The receipt source includes actual Capsule/Box Shape3D resource `get_instance_id()` integers in its `native` array. Those RefCounted IDs use the full signed64 native domain, while original Exact rejects integers outside±9,007,199,254,740,991. Existing actual4.7 witness `focused-native.exact.json` retains shape IDs such as−9223371071913194019,−9223371071493764167 and−9223371071074333656 as decimal Strings; the existing stage adapter also explicitly tags out-of-range native ints. This is a sufficient source-domain cause for Exact rejection before a size result exists. The first ownership payload was never written, so its exact first failing ID and serialized length are unavailable. The original combined OR/message proves neither a two-MiB overflow nor a depth/node failure; those stronger claims are not made.

The repair changes only diagnostic encoding and evidence refusal reporting. Outside-Exact native ints receive `{native_type: int64, decimal: str(original_integer)}` with full canonical signed64 text, preserving type and every integer bit without conversion to floating point. Safe ints, all float64 Exact bits, native tags, complete pair records, original/candidate result strings and native observations remain. Actual before/after native comparison receipts still contain their original integers; every actual comparison/control/cleanup assertion and its order remains literal.

When Exact serialization returns an empty String, the failure handler reports the unchanged Exact encoder's actual refusal reason using its original budgets. A separately encoded output larger than2,097,152 bytes keeps the original two-MiB refusal. No Exact safe-int/depth64/entries16,384/nodes262,144/bytes8MiB bound or diagnostic two-MiB bound changes. No records are omitted or normalized, and no new mechanical control is introduced. The native retry should print110/0 if it succeeds: the original111st assertion was the failed evidence-write branch, not a removed successful control.

Repaired GDScript remains unparsed/unexecuted. Root may inspect the exact correction then run:

```
python3 .cinder/shared59-runtime-cost-next/run_ownership.py parse ownership-parse02
python3 .cinder/shared59-runtime-cost-next/run_ownership.py native ownership-native02
```

The runner is unchanged. No helper engine job, timing sample, import, UID, production change, bank census or further audit occurred. Host checks prove unchanged pre-encoder/control functions, unchanged finish/cleanup, literal runtime seals, archive/job bytes and Python AST validity. Native serialization/equivalence still require Root's actual retry; no new passing native evidence is claimed.
