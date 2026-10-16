# Closed L5 comparison01 — source-backed TEST contract diagnosis

Diagnosis only. The hypothesis is stopped; no fixture/runtime/shared repair, replacement trial or engine run was performed. This note does not authorize a rerun. Original eight-level/campaign acceptance remains historical and separate.

## Actual closed scope

`.cinder/l5-policy-runs/compare-01` closed native exit1 at `2026-10-16T10:23:19.541560+00:00`, HEAD `97c885049200b7a1446f4966f92112d56f5da845`, Shared74. Footer: **568 checks /57 failures /396 actual observed native ticks /0 completed cases**, outcome `incomplete-native-case`. The canonical component did not complete; the changed west-inset cell was never constructed. There is no paired layout comparison, novelty verdict, new portrait or completed safe-C50 case from this run.

Raw log SHA256 `ce602a8d7a9c554c05e07fa0b107141a1586a5c720873c393acded1670287908`. Literal `native-results.var.bin` remains retained at12,907,720 bytes, SHA256 `f98d98713e7dfb2179ce541ff4b79a5f6503df5b4e4b3b01be2aefdc23a78dd8`. Its bytes were hashed, not decoded or rewritten for this diagnosis. The native finalizer source preserves the complete failure trace; no unread binary field is represented here as an inspected operand.

The actual result reports no selected source changes during execution and no generated UID observations. Both the frozen source blobs and current physical files match the selected fixture `3a20abbafe49012e104472e2693c1942e8e80d20cc30c33e542b40227b23fb15` and Scheduler `c28ea9f4cd6c1ff9aedbc9cfc45a28826c589c095b9193b565f45d23c3df903d`. Approach was the frozen `dd7272f7…`; no source drift was used to explain this failure.

## Concrete assertion error belongs to the TEST contract

Fixture `tests/acts/act3/crystalman_plain_comparison_smoke.gd:256` unconditionally requires every selected native lease to contain `response_actor_instance_id == hero.get_instance_id()`, in addition to the settled control/source/lease joins.

The actual Scheduler contract does not supply that field for ordinary C50 reservations:

- `scripts/combat/threat_scheduler.gd:181` `_prepare_ordinary_attack` constructs ordinary geometry/deadlines/opening, then sets source instance/position, start/lock/cooldown, profile and world fields at218–224. It does not add a response actor ID.
- `_commit_ordinary_attack` at228–248 copies that candidate and adds reservation ID, owner WeakRef and floor guards. It still does not add a response actor ID.
- `source_control_state(owner)` at1224–1243 selects the genuine retained owner and returns its actual source ID, settled state and `_public_record(record)` reservations.
- `_public_record` at1261–1271 copies the record, removes private references and adds derived `armed`/`state`; it does not invent a missing actor field.
- The authored-replay constructor at283 explicitly adds `response_actor_instance_id`. That replay-specific wire fact was incorrectly generalized to ordinary C50 by my fixture assertion.

Therefore, whenever this assertion reaches a valid ordinary C50 lease, `.get("response_actor_instance_id")` yields null and cannot equal the genuine existing Hero ID. An absent field is valid ordinary API behavior, not evidence that Scheduler selected a wrong Hero or lost native custody. The native log does not print individual identity operands, so this source proof does not claim every other conjunct was inspected true at every occurrence. It does identify a sufficient unavoidable TEST failure for ordinary leases.

## Why execution continued and produced57 failures

An exact raw-log count finds **55** instances of the identity assertion, followed by two distinct downstream assertions. Thus beyond the first failure there are54 further identity failures plus2 downstream failures, not56 additional instances of the same identity error.

The repetition is explained directly by fixture control flow:

1. `_pc_fresh:256` increments failure through `expect`, then returns an empty Dictionary without setting `_pc_done`.
2. `_pc_response:238–243` treats empty as “no usable response yet”, awaits another real tick and retries. It does not check the failure counter. The rejected lease is not marked used because that assignment occurs only for a nonempty selection at241.
3. `tick:381–404` also has no failure-count short circuit; its stop flags are `_pc_done`, `_pc_finished`, pause/observer/native-safety conditions. It continues normal autonomous physics while the same warning is considered again. The outer `_pc_case:224` failure check cannot execute until the awaited `_pc_response` returns.
4. At native clock6.6 the log records actual C50 consumed contact and Hero HP88, triggering the existing zero-contact/full-HP tick guard. That causes `_pc_response` to return empty. `_pc_case:232–233` then emits the final incomplete-case assertion.

The actual raw distribution is55 identity assertions +1 consumed-contact/full-HP tick failure +1 incomplete-case assertion =57. The later C50 hit is a real failed invariant in this run; it is not suppressed or relabeled a pass. It followed a TEST loop that refused the valid ordinary response contract and continued physics without acting on that response. It consequently does not establish a production proof, timing, camera, guard or selected-layout defect.

## Limit and stop

This evidence establishes the fixture contract error and its repeated-failure control flow. It does not establish whether both layouts have a safe useful complete response, whether their decision composition differs, or whether a changed arrangement is harder. All original failed bytes remain authoritative. No corrected source or repaired trial is supplied by this diagnosis.
