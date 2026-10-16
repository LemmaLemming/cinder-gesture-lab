# Evidence-only v3

Native controller/proof/geometry behavior is byte-identical to reviewed private v2 da9e5549303c9c079615fd8cdd77c65f20dd4ac66c3cebc700c082d6a87f8f4d. No parse/native execution is claimed. Original actual compare01 at2e61c9c/driver55295ace remains failed712/1,338 actual physics ticks, one diagnostic, raw64f324e6. The earlier analysis remains in LIVE_UNION_CORRECTION.md; neither v2 nor v3 has gameplay credit.

The sole v3 correction concerns literal test result custody:

- `_close` caches the actual available current native observation, pure retained owner-control receipts, native actions/events, real Scheduler clock and the cumulative `_hc_native_ticks` BEFORE detaching callbacks or disposing nodes. `_finish` may be called after an earlier `_close`; the retained cache is not overwritten by null bindings. A preconstruction failure records unavailable native observation/null clock explicitly, not invented actors or time.
- `current_case_complete` derives from actual completed result membership. A successful transport return adds its own literal completed TEST transport result; an absent/failed case is not credited. No per-case physics count is inferred from the global counter.
- A case's full literal Variant bytes and text are frozen while its native actors remain alive. This prevents later serialization of freed prior-case actor references; binary observations are evidence only, never restore authority. The outer result stores these frozen receipts and the pre-cleanup frozen observation alongside scalar metadata.
- Any failure emits a result, even the first case before any completed/declined plan. Actual post-cleanup checks/failures/global native counter and remaining enemy/cue group counts are separate, so cleanup assertions cannot be hidden by the earlier pre-cleanup counters.

Only `_run`'s successful transport result recording, new evidence-cache helper, `_close`'s cache call and `_finish`'s output changed from da9. All actual response selection/current-union checks, action dispatch, native proof/deadlines, primary/HP/kit/floor/Camera guards, finite bounds and cancellation/disposal actions remain unchanged.

## Conservative original crossing-segment query

The v2/v3 union query selects original native proof rows whose original `end_s >= actual_now`. It does not clip or re-time a row starting before now: the entire original crossing segment is checked with its original from/to/start/end and each actual lease's exact native active interval. This is deliberately conservative and can include a historical prefix of that one crossing row. Therefore a query refusal is recorded as a conservative check of the original plan, not a proof that all future paths are impossible or that the actor actually traversed the historical theoretical row. A replacement still requires an existing actual fresh same-origin native proof; no synthetic path/time/state repair is introduced. If no such proof exists, the test reports the bounded refusal to Root. Actual failed-run Enclose/helper windows are established independently by the retained native proof/state timeline.

Files: live-union-v3.patch is the full55295ace→v3 patch; live-union-v3-evidence-only.patch is the narrow reviewed-da9→v3 evidence delta. Original5529, v2da9 and both patches remain separate/private. Root owns promotion, parser/native qualification and first-failure handling; no owned/shared file was changed here.
